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
        f = get_parse_error_field(e)
        return errors[:computed] = "- Error in field #{f}: #{e} "
      end
    end
  end

  def get_parse_error_field(exc)
    kl = engine && engine.constantize || Marty::RuleScriptSet
    begin
      line = exc.line ? exc.line - kl.body_lines : 0
    rescue => e
      binding.pry
    end
    errs = {}
    errs[:computed_guards] = computed_guards.keys.count

    # 1 code line per each grid
    # plus 2 per each unique grid
    # plus 2 code lines for pt and params__
    gridlines = grids.present? ? 2 + grids.values.to_set.count * 2 +
                                 grids.keys.count : 0
    errs[:grids] = gridlines
    errs[:results] = results.keys.count
    line_count = 0
    errs.each do |k,v|
      line_count += v
      return k if line <= line_count
    end
    errs.keys.last
  end

  def compute(params)
    eclass = engine && engine.constantize || Marty::RuleScriptSet
    engine = eclass.new(params["pt"]).get_engine(self) if
      computed_guards.present? || results.present?

    if computed_guards.present?
      cg_keys = computed_guards.keys
      begin
        res = engine.evaluate(eclass.node_name,
                              cg_keys,
                              params.clone)
      rescue => e
        raise e, "Error (guard) in rule '#{id}:#{name}': #{e}", e.backtrace
      end
      return Hash[cg_keys.zip(res).select{|k,v| !v}] unless res.all?
    end

    if results.present?
      compute_keys = results.keys.reject{|k|k.starts_with?("tmp_")} + grids.keys
      begin
        eval_result = engine.evaluate(
          eclass.node_name,
          compute_keys,
          params + {
            "params__" => params
          })
      rescue => e
        raise e, "Error (result) in rule '#{id}:#{name}': #{e}", e.backtrace
      end
      Hash[compute_keys.zip(eval_result)]
    end
  end

  def self.get_matches_(pt, attrs, params)
    q = super(pt, attrs.except("rule_dt"), params)
    rule_dt = attrs["rule_dt"]
    q=q.where("start_dt <= ?", rule_dt).
       where("end_dt >= ? OR end_dt IS NULL", rule_dt) if rule_dt
    #puts q.to_sql
    q.order("start_dt DESC NULLS LAST")
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

end
