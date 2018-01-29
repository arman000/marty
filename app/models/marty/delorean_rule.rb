class Marty::DeloreanRule < Marty::BaseRule
  self.abstract_class = true

  validates_presence_of :rule_type, :start_dt

  def validate
    super
    if self.class.where(obsoleted_dt: 'infinity', name: name).
        where.not(id: id).
        where("(start_dt, coalesce(end_dt, 'infinity')) OVERLAPS (?, ?)",
              start_dt, end_dt || 'infinity').exists?
      return errors[:base] <<
             "Can't have rule with same name and overlapping start/end dates"\
             " - #{name}"
    end

    return errors[:base] = "Start date must be before end date" if
      start_dt && end_dt && start_dt >= end_dt

    if computed_guards.present? || results.present?
      begin
        eclass = engine && engine.constantize || Marty::RuleScriptSet
        eng = eclass.new('infinity').get_engine(self)
      rescue => e
        return errors[:computed] = "- " + e.message
      end
    end
  end

  def self.find_fixed(results)
    results.each_with_object({}) do |(k, v), h|
      v_wo_comment = /\A([^#]+)/.match(v)[1] if v.include?("#")
      # if v contains a #, try cut it there and attempt parse that way first
      jp = (v_wo_comment && JSON.parse("[#{v_wo_comment}]") rescue nil) ||
           (JSON.parse("[#{v}]") rescue nil)
      next h[k] = jp[0] if jp
      # json doesn't like single quotes, so handle those manually
      m = %r{\A'(.*)'\z}.match(v)
      next unless m
      h[k] = m[1]
    end
  end

  before_validation(on: [:create, :update]) do
    # identify result values that are fixed, stash them (removing quotes)
    self.fixed_results = self.class.find_fixed(self.results)
  end

  def self.results_cfg_var
    "NOT DEFINED"
  end

  def compg_keys
    computed_guards.keys
  end

  def compres_keys
    defkeys = (Marty::Config[self.class.results_cfg_var] || {}).keys +
              ["adjustment", "breakeven"]
    results.keys.select{|k| defkeys.include?(k)} + grid_keys
  end
  def grid_keys
      grids.keys.map{|k|k.ends_with?("_grid") ? k : k + "_grid"}
  end
  def base_compute(params, dgparams=params)
    eclass = engine && engine.constantize || Marty::RuleScriptSet
    engine = eclass.new(params["pt"]).get_engine(self) if
      computed_guards.present? || results.present?

    if computed_guards.present?
      begin
        res = engine.evaluate(eclass.node_name,
                              compg_keys,
                              params.clone)
      rescue => e
        raise e, "Error (guard) in rule '#{id}:#{name}': #{e}", e.backtrace
      end
      return Hash[compg_keys.zip(res).select{|k,v| !v}] unless res.all?
    end
    grids_computed = false
    grid_results = {}
    if (results.keys - fixed_results.keys).present?
        begin
          eval_result = engine.evaluate(
            eclass.node_name,
            compres_keys,
            params + {
              "dgparams__" => dgparams,
            })
          grids_computed = true
        rescue => e
          raise e, "Error (results) in rule '#{id}:#{name}': #{e}", e.backtrace
        end
        result = Hash[compres_keys.zip(eval_result)]
    elsif fixed_results.keys.sort == results.keys.sort
      result = fixed_results
    end
    if grids.present? && !grids_computed
      pt = params['pt']
      gres = {}
      grid_results = grids.each_with_object({}) do |(gvar, gname), h|
        usename = gvar.ends_with?("_grid") ? gvar : gvar + "_grid"
        next h[usename] = gres[gname] if gres[gname]
        dg = Marty::DataGrid.lookup(pt,gname)
        dgr = dg && dg.lookup_grid_distinct_entry(pt, dgparams)
        h[usename] = gres[gname] = dgr["result"] if dgr
      end
    end
    result + grid_results
  end

  def self.get_matches_(pt, attrs, params)
    q = super(pt, attrs.except("rule_dt"), params)
    rule_dt = attrs["rule_dt"]
    q=q.where("start_dt <= ?", rule_dt).
       where("end_dt >= ? OR end_dt IS NULL", rule_dt) if rule_dt
    #puts q.to_sql
    q.order("start_dt DESC NULLS LAST")
  end

end
