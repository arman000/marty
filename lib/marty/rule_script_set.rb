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
    equals, rhs = v == :parameter ? [" =?", ""] :
                    [" =", "\n" + v.lines.map { |l| " " * 8 + l }.join("\n")]
    k + equals + rhs
  end

  def paramify_h(h)
    "{" + h.keys.reject { |k| k.ends_with?("__") }.
                         map { |k| %Q("#{k}": #{k}) }.join(",\n") + "}"
  end

  def self.grid_final_name(dgid)
    dgid.ends_with?("_grid") ? dgid + "_result" : dgid + "_grid_result"
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
      expand_grid_code(h, k.ends_with?('_grid') ? k : k + '_grid', %Q("#{v}"),
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
       ruleh["results"].keys.any? { |k| k.ends_with?("_grid") }
      write_code({ "pt" => :parameter,
                   "dgparams__" => :parameter,
                 })
    else
      ''
    end
  end

  def get_code(ruleh)
    grid_i = grid_init(ruleh)
    grid_c = grid_code(ruleh)
    result_c = result_code(ruleh)
    guard_c = guard_code(ruleh)

    code = self.class.body_start +
           self.class.indent(grid_i + guard_c + grid_c + result_c)
    # puts '='*40
    # puts ruleh["name"]
    # puts '-'
    # puts code
    # puts '-'*10

    code
  end

  def code_section_counts(ruleh)
    errs = {}
    errs[:grid_params] = grid_init(ruleh).count("\n")
    errs[:computed_guards] = guard_code(ruleh).count("\n")
    errs[:grids] = grid_code(ruleh).count("\n")
    errs[:results] = result_code(ruleh).count("\n")
    errs
  end

  def get_parse_error_field(ruleh, exc)
    line = exc.line ? exc.line - self.class.body_lines : 0
    errs = code_section_counts(ruleh)
    line_count = 0
    errs.each do |k, v|
      line_count += v
      return k if line <= line_count
    end
    errs.keys.last
  end

  def get_engine(ruleh)
    begin
      # if rule is a str => importing a regular Script (i.e. not rule)
      return sset.get_engine(ruleh) if ruleh.is_a? String

      # on create rule doesn't have an id => don't cache
      return sset.parse_check("New RULE #{ruleh['name']}", get_code(ruleh)) unless
        ruleh["id"]

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

        @@dengines[sname] = sset.parse_check(sname, get_code(ruleh))
      else
        engine = @@engines[[pt, sname]]

        return engine if engine

        @@engines[[pt, sname]] = sset.parse_check(sname, get_code(ruleh))
      end
    rescue Delorean::ParseError => e
      f = get_parse_error_field(ruleh, e)
      msg = e.message.capitalize
      raise "Error in rule '#{ruleh['name']}' field '#{f}': #{msg}"
    end
  end

  def self.indent(s)
    s.gsub(/^/, ' ' * 4)
  end
end
