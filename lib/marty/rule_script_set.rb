class Marty::RuleScriptSet < Delorean::AbstractContainer
  attr_reader :sset, :pt

  def self.clear_cache
    @@engines, @@dengines, @@dengines_dt = {}, {}, nil
  end

  clear_cache

  def self.node_name
    "Node"
  end
  def self.body_start
    "#{node_name}:\n"
  end
  def self.body_lines
    self.body_start.count("\n")
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
    k + (v == :parameter ? " =?" : " = #{v}")
  end

  def paramify_h(h)
    "{" + h.keys.reject{|k|k.ends_with?("__")}.
                         map {|k| %Q("#{k}": #{k}) }.join(",\n") + "}"
  end

  def expand_grid_code(h, dgid, dgname, cache, extra_params)
    final_name = dgid.ends_with?("_grid") ?  dgid + "_result" :
                   dgid + "_grid_result"
    if cache[dgname]
      h[final_name] = "#{cache[dgname]}"
    else
      h["#{dgid}_dg__"] = <<~EOS
      Marty::DataGrid.lookup(pt,'#{dgname}') ||
        ERR("grid '#{dgid}' ('#{dgname}') not found")
      EOS
      h["#{dgid}_dgp__"] = "dgparams__ + \n" + self.class.indent(paramify_h(h))
      lgde = "lookup_grid_distinct_entry"
      h["#{dgid}_h__"] = "#{dgid}_dg__.#{lgde}(pt,#{dgid}_dgp__)"
      h[final_name] = "#{dgid}_h__ && #{dgid}_h__.result"
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

  def grid_code(rule)
    dgcache = {}
    h = {}
    rule.grids.each do |k, v|
      expand_grid_code(h, k, v, dgcache, {})
    end
    h.map { |k, v| write_attr(k, v) }.join("\n") + "\n"
  end

  def guard_code(rule)
    write_code(rule.computed_guards)
  end

  def result_code(rule)
    write_code(rule.results)
  end

  def grid_init(rule)
    if rule.grids.present? || rule.results.keys.any?{|k|k.ends_with?("_grid")}
      write_code({ "pt" => :parameter,
                   "dgparams__" => :parameter,
                 })
    else
      ''
    end
  end
  def get_code(rule)
    grid_i = grid_init(rule)
    grid_c = grid_code(rule)
    result_c = result_code(rule)
    guard_c = guard_code(rule)

    code = self.class.body_start + self.class.indent(grid_i +
                                                     guard_c +
                                                     grid_c +
                                                     result_c)
    #puts '='*40
    #puts rule.name
    #puts '-'
    #puts code
    #puts '-'*10

    code
  end

  def code_section_counts(rule)
    errs = {}
    errs[:grid_params] = grid_init(rule).count("\n")
    errs[:computed_guards] = guard_code(rule).count("\n")
    errs[:grids] = grid_code(rule).count("\n")
    errs[:results] = result_code(rule).count("\n")
    errs
  end
  def get_parse_error_field(rule, exc)
    line = exc.line ? exc.line - self.class.body_lines : 0
    errs = code_section_counts(rule)
    line_count = 0
    errs.each do |k,v|
      line_count += v
      return k if line <= line_count
    end
    errs.keys.last
  end

  def get_engine(rule)
    begin
      # if rule is a str => importing a regular Script (i.e. not rule)
      return sset.get_engine(rule) if rule.is_a? String

      # on create rule doesn't have an id => don't cache
      return sset.parse_check("New RULE #{rule.name}", get_code(rule)) unless
        rule.id

      rule_pfx = rule.class.name.demodulize

      # unique name for specific version of rule
      sname = "#{rule_pfx}_#{rule.group_id}_#{rule.created_dt.to_f}"

      # is it a dev posting?
      if Mcfly.is_infinity(pt)
        max_dt = rule.class.
                 order("created_dt DESC").limit(1).pluck(:created_dt).first

        @@dengines_dt ||= max_dt

        # reset dengine cache if an rule has changed
        @@dengines = {} if max_dt > @@dengines_dt

        engine = @@dengines[sname]

        return engine if engine

        @@dengines[sname] = sset.parse_check(sname, get_code(rule))
      else
        engine = @@engines[[pt, sname]]

        return engine if engine

        @@engines[[pt, sname]] = sset.parse_check(sname, get_code(rule))
      end
    rescue Delorean::ParseError => e
      f = get_parse_error_field(rule, e)
      raise "Error in rule '#{rule.name}' field '#{f}': #{e}"
    end
  end

  def self.indent(s)
    s.gsub(/^/, ' '*4)
  end
end
