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

  def get_code(rule)
    cache = {}
    dghash = { "pt" => :parameter,
               "params__" => :parameter }
    dgres = rule.grids.each_with_object(dghash) do
      |(dgid, dgname), h|
      if cache[dgname]
        h[dgid] = "#{cache[dgname]}"
      else
        h["#{dgid}_dg__"] = "Marty::DataGrid.lookup(pt,'#{dgname}')"
        h["#{dgid}_h__"] = "#{dgid}_dg__.lookup_grid_distinct_entry(pt,params__)"
        h[dgid] = "#{dgid}_h__ && #{dgid}_h__.result"
        cache[dgname] = dgid
      end
    end
    computed_w_grids = dgres + rule.computed_results

    write = lambda { |k, v| k + (v == :parameter ? " =?" : " = #{v}") }

    cguards_part = rule.computed_guards.blank? ? '' :
                     rule.computed_guards.map(&write).join("\n") + "\n"
    results_part = computed_w_grids.map(&write).join("\n")
    code = self.class.body_start + self.class.indent(cguards_part +
                                                     results_part)
    #puts '='*40
    #puts code
    #puts '-'*10
    code
  end

  def get_engine(rule)
    # if rule is a str => importing a regular Script (i.e. not rule)
    return sset.get_engine(rule) if rule.is_a? String

    # on create rule doesn't have an id => don't cache
    return sset.parse_check("New RULE #{rule.name}", get_code(rule)) unless
      rule.id

    # unique name for specific version of rule
    sname = "RULE_#{rule.group_id}_#{rule.created_dt.to_f}"
    # is it a dev posting?
    if Mcfly.is_infinity(pt)
      max_dt = Marty::Rule.
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
  end

  def self.indent(s)
    s.gsub(/^/, ' '*4)
  end
end
