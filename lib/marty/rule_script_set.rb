class Marty::RuleScriptSet < Delorean::AbstractContainer
  attr_reader :sset, :pt

  def self.clear_cache
    @@engines, @@dengines, @@dengines_dt, @@mengines = {}, {}, nil, {}
  end

  clear_cache

  class CodeBuilder
    def initialize
      @code = {code: "",
               locs: {},
               lineno: 0}
    end
    def add(code, name_and_sec)
      return if code.blank?
      @code[:code] << code
      lcnt = code.lines.count
      cur = @code[:lineno]
      @code[:locs][[cur, cur+lcnt-1]] = name_and_sec
      @code[:lineno]+= lcnt
    end
    def get_code
      @code[:code]
    end
    def get
      @code
    end
    def error_section(lineno)
      @code[:locs].detect{|(st, nd), desc| lineno.between?(st, nd)}.try(:second)
    end
  end

  def self.node_name(ruleh)
    "Node"
  end

  def self.params_extra_code(ruleh)
    nil
  end

  def self.body_extra_code(ruleh)
    nil
  end

  def self.script_imports(ruleh)
    []
  end

  def self.node_parent(ruleh)
    nil
  end

  def self.final_node
    "Final"
  end

  def initialize(pt)
    @pt = Mcfly.normalize_infinity(pt)

    # if pt is Infinity, we get a DEV Tag
    tag = Marty::Tag.cached_find_match(pt)
    @sset = Marty::ScriptSet.new(tag)
    super()
  end

  def parse_check(sname, body)
    sset.parse_check(sname, body)
  end

  def write_attr(k, v)
    equals, rhs = v == :parameter ? [" =?", ""] :
                    [" =", "\n" + v.lines.map{|l| " "*8 + l}.join("\n")]
    k + equals + rhs
  end

  def paramify_h(h)
    "{" + h.keys.reject{|k|k.ends_with?("__")}.
                         map {|k| %Q("#{k}": #{k}) }.join(",\n") + "}"
  end

  def self.grid_final_name(dgid)
    dgid.ends_with?("_grid") ?  dgid + "_result" : dgid + "_grid_result"
  end
  def expand_grid_code(h, dgid, dgname, cache, extra_params)
    final_name = self.class.grid_final_name(dgid)
    if cache[dgname]
      h[final_name] = "#{cache[dgname]}"
    else
      h[dgid] = dgname
      h["#{dgid}_dgp__"] = "dgparams__ + \n" + self.class.indent(paramify_h(h))
      lgde = "lookup_grid_h"
      h[final_name] = "Marty::DataGrid.#{lgde}(pt,#{dgid},#{dgid}_dgp__,true)"
      cache[dgname] = final_name
    end
  end

  def write_code(attrs)
    return '' if attrs.blank?
    newh = attrs.each_with_object({}) do |(k, v), h|
      if k.ends_with?("_grid")
        expand_grid_code(h, k, v, {}, h)
      else
        h[k] = v
      end
    end
    newh.map { |k, v| write_attr(k, v) }.join("\n") + "\n"
  end

  def grid_code(ruleh)
    dgcache = {}
    h = {}
    ruleh["grids"].each do |k, v|
      expand_grid_code(h, k.ends_with?('_grid')?k:k+'_grid', %Q("#{v}"),
                                                dgcache, {})
    end
    h.map { |k, v| write_attr(k, v) }.join("\n") + "\n"
  end

  def guard_code(ruleh)
    write_code(ruleh["computed_guards"])
  end

  def result_code(ruleh)
    write_code(ruleh["results"])
  end

  def grid_init(ruleh)
    if ruleh["grids"].present? ||
       ruleh["results"].keys.any?{|k|k.ends_with?("_grid")}
      write_code({ "pt" => :parameter,
                   "dgparams__" => :parameter,
                 })
    else
      ''
    end
  end

  def result_agg_code(ruleh, id)
    cgs = ruleh['computed_guards'].keys
    cgval = '{' +
            cgs.map{|cg| %Q("#{cg}": [#{cg}].flatten)}.join(",\n    ") +
            '}'
    res = ruleh['result_keys']
    resval = '{ ' + res.map do |r|
      %Q("#{r}": #{r})
    end.join(",\n    ") + ' }'
    agg = <<~EOC
    cgs = #{cgs}
    cgval = #{cgval}
    cgres = [ v for cgkey, v in cgval if v.first ]
    resval = #{resval}
    EOC
  end

  def final_code(ruleh, nodes)
    nodestr = nodes.map{|node, id| "#{id}: (#{node}() + _)"}.join(",\n        ")
    code = <<~EOC
    #{self.class.final_node}:
        eval_rule_gids =?
        nodes = {#{nodestr}}
        raw = [[id,
                nodes[id] / "cgs",
                nodes[id] / "cgval",
                nodes[id] / "cgres",
                nodes[id]]
               for id in eval_rule_gids]
        result0 = [[id,  if cgval.error then
                      {"runtime error": cgval.error,
                       "section": "guard"} else
                      if cgres.length == cgs.length then
                        nc() / "resval"
                      else { cgkey: v[1] for cgkey, v in cgval if v[1] }]
                    for id, cgs, cgval, cgres, nc in raw]
        result = {id: if res.error then
                   {"runtime error": res.error,
                    "res": res,
                    "section": "results"} else res
                   for id, res in result0}

    EOC
  end

  def get_one(ruleh, cb, node=self.class.node_name(ruleh), include_agg=false)
    id, name = ruleh.values_at('group_id', 'name')
    add = lambda{|code_raw, section, indent=true|
      code = indent ? self.class.indent(code_raw) : code_raw
      cb.add(code, [name, section])
    }
    np = self.class.node_parent(ruleh)
    add.call("#{node}: #{np}\n", 'declaration', false)
    add.call(self.class.params_extra_code(ruleh), 'params_extra1')
    add.call(ruleh['params_extra_code']||'', 'params_extra2')
    add.call(grid_init(ruleh), 'grid params')
    add.call(guard_code(ruleh), 'computed_guards')
    add.call(grid_code(ruleh), 'grids')
    add.call(self.class.body_extra_code(ruleh), 'body_extra1')
    add.call(ruleh['body_extra_code']||'', 'body_extra2')
    add.call(result_code(ruleh), 'results')
    add.call(result_agg_code(ruleh, id), 'result_aggregate') if
      include_agg
  end

  def get_code(ruleh_a)
    cb = CodeBuilder.new
    cb.add(self.class.script_imports(ruleh_a).map do
             |i|
             "import #{i}\n"
           end.join, "imports")
    if ruleh_a.is_a?(Array)
      nodes = []
      ruleh_a.each do |ruleh|
        id = ruleh['group_id']
        node = self.class.node_name(ruleh) + id.to_s
        nodes.append([node, id])
        get_one(ruleh, cb, node, true)
      end
      cb.add(final_code(ruleh_a, nodes), 'final')
    else
      get_one(ruleh_a, cb)
    end

    # comment out later
    File.open("/tmp/rss.txt", "a") do |f|
      f.puts '='*40
      f.puts cb.get_code
      f.puts '-'*10
    end if false
    cb
  end

  def get_engine(ruleh)
    begin
      # if rule is a str => importing a regular Script (i.e. not rule)
      return sset.get_engine(ruleh) if ruleh.is_a? String

      cb = nil
      code = nil
      getfn = lambda {
        cb||=get_code(ruleh)
        cb.get_code
      }
      # on create rule doesn't have an id => don't cache
      return sset.parse_check("New RULE #{ruleh['name']}",
                              getfn.call) unless ruleh["id"]


      rule_pfx = ruleh["classname"].demodulize

      # unique name for specific version of rule
      sname = "#{rule_pfx}_#{ruleh['group_id']}_#{ruleh['created_dt'].to_f}"

      # is it a dev posting?
      if Mcfly.is_infinity(pt)
        max_dt = ruleh["classname"].constantize.order("created_dt DESC").
                 limit(1).pluck(:created_dt).first

        @@dengines_dt ||= max_dt

        # reset dengine cache if an rule has changed
        @@dengines = {} if max_dt > @@dengines_dt

        engine = @@dengines[sname]

        return engine if engine

        @@dengines[sname] = sset.parse_check(sname, getfn.call)
      else
        engine = @@engines[[pt, sname]]

        return engine if engine

        @@engines[[pt, sname]] = sset.parse_check(sname, getfn.call)
        #sset.parse_check(sname, getfn.call)
      end
    rescue Delorean::ParseError => e
      rulename, section = cb.error_section(e.line)
      msg = e.message
      raise "Error in rule '#{rulename}' field '#{section}': #{msg.capitalize}"
    end
  end

  #FIXME dry this code? (and #get_engine)
  def get_multi_engine(model, ruleh_fn, sname)
    begin
      cb = nil
      code = nil
      ruleh_a = nil
      getfn = lambda {
        ruleh_a = ruleh_fn.call
        cb||=get_code(ruleh_a)
        cb.get_code
      }
      # is it a dev posting?
      if Mcfly.is_infinity(pt)
        max_dt = model.order("created_dt DESC").
                 limit(1).pluck(:created_dt).first

        @@dengines_dt ||= max_dt

        # reset dengine cache if an rule has changed
        @@dengines = {} if max_dt > @@dengines_dt

        engine = @@dengines[sname]

        return engine if engine

        @@dengines[sname] = sset.parse_check(sname, getfn.call)
      else
        engine = @@engines[[pt, sname]]

        return engine if engine
        @@engines[[pt, sname]] = sset.parse_check(sname, getfn.call)
        #sset.parse_check(sname, getfn.call)
      end
    rescue Delorean::ParseError => e
      rulename, section = cb.error_section(e.line)
      msg = e.message
      msg.sub!(' '+sname, '') if sname
      raise "Error in rule '#{rulename}' field '#{section}': #{msg.capitalize}"
    end

  end

  def self.indent(s)
    return nil if s.blank?
    s.gsub(/^/, ' '*4)
  end
end
