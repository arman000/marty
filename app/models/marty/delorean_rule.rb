class Marty::DeloreanRule < Marty::BaseRule
  self.abstract_class = true

  validates_presence_of :rule_type, :start_dt

  def validate
    super
    return errors[:base] << "Start date must be before end date" if
      start_dt && end_dt && start_dt >= end_dt

    if computed_guards.present? || results.present?
      begin
        eclass = engine && engine.constantize || Marty::RuleScriptSet
        eng = eclass.new('infinity').get_engine(self_as_hash)
      rescue => e
        return errors[:computed] << "- " + e.message
      end
    end
  end

  def self_as_hash
    self.attributes + {"classname"=>self.class.name}
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

  def self.compg_keys(computed_guards)
    computed_guards.keys
  end

  def self.comp_res_keys(results, grids, ecl, pcfg = nil)
    defkeys = (pcfg || Marty::Config[results_cfg_var] || {}).keys
    results.keys.map {|k| k.ends_with?("_grid") ? ecl.grid_final_name(k) : k}.
       select{|k| defkeys.include?(k)} + grid_keys(grids, ecl)
  end
  def self.grid_keys(grids, eclass)
      grids.keys.map{|k| eclass.grid_final_name(k) }
  end

  class ComputeError < StandardError
    attr_reader :input, :section

    def initialize(msg, stack, input, section)
      @input = input
      @section = section
      super(msg)
      set_backtrace stack
    end
  end

  def self.base_compute2(ruleh, metadata_opts, params, dgparams=params)
    begin
      id, name, eclassname, computed_guards, grids, results, fixed_results =
          ruleh.values_at("id", "name", "engine", "computed_guards", "grids",
                          "results", "fixed_results")
      eclass = eclassname && eclassname.constantize || Marty::RuleScriptSet
      engine = eclass.new(params["pt"]).get_engine(ruleh) if
        computed_guards.present? || results.present?

      cgres = nil
      resres = nil
      cg_keys = compg_keys(computed_guards)
      emsg = nil
      estack = nil
      esec = nil

      if computed_guards.present?
        begin
          cgres = engine.evaluate(eclass.node_name, cg_keys,
                                  params.clone)
        rescue => e
          emsg = e.message
          estack = e.backtrace
          esec = 'computed_guards'
          raise ComputeError.new(
                  "Error (guard) in rule '#{id}:#{name}': #{emsg}",
                  estack,
                  params.clone,
                  esec)
        end
        return Hash[compg_keys(computed_guards).zip(cgres).select{|k,v| !v}] unless
          cgres.all?
      end

      grids_computed = false
      grid_results = {}
      grkeys = grid_keys(grids, eclass)
      crkeys = comp_res_keys(results, grids, eclass, metadata_opts)
      if (crkeys - grkeys - fixed_results.keys).present?
        begin
          resres = engine.evaluate(
            eclass.node_name,
            crkeys,
            params + {
              "dgparams__" => dgparams,
            })
          grids_computed = true
        rescue => e
          emsg = e.message
          estack = e.backtrace
          esec = 'results'
          raise ComputeError.new(
                  "Error (results) in rule '#{id}:#{name}': #{emsg}",
                  estack,
                  params + {
                    "dgparams__" => dgparams,
                  },
                  esec)
        end
        result = Hash[crkeys.zip(resres)]
      else
        result = fixed_results.slice(*crkeys)
      end

      if grids.present? && !grids_computed
        pt = params['pt']
        gres = {}
        grid_results = grids.each_with_object({}) do |(gvar, gname), h|
          usename = eclass.grid_final_name(gvar)
          next h[usename] = gres[gname] if gres[gname]
          dg = Marty::DataGrid.lookup_h(pt,gname)
          dgr = dg && Marty::DataGrid.lookup_grid_distinct_entry_h(pt, dgparams,
                                                                   dg)
          h[usename] = gres[gname] = dgr["result"] if dgr
        end
      end
      result + grid_results
    ensure
      Marty::Logger.info("Rule Log #{ruleh['name']}",
                         { input: params,
                           dgparams: dgparams,
                           gr_keys: grkeys,
                           gr_result: grid_results,
                           cg_keys: cg_keys,
                           cg_result: cgres,
                           res_keys: crkeys,
                           res_result: resres,
                           error_section: esec,
                           error_message: emsg,
                           error_stack: estack && estack.select{
                             |l|
                             l.starts_with?('DELOREAN')}
                         }.compact) if ruleh['fixed_results']['log__']
    end
  end
  def self.base_compute(ruleh, params, dgparams=params)
    base_compute2(ruleh, nil, params, dgparams)
  end
  delorean_fn :route_compute, sig: 4 do
    |ruleh, pt, params, grid_names_p|
    kl = ruleh["classname"].constantize
    kl.compute(ruleh, nil, pt, params, grid_names_p)
  end
  delorean_fn :route_compute2, sig: 5 do
    |ruleh, metadata_opts, pt, params, grid_names_p|
    kl = ruleh["classname"].constantize
    kl.compute(ruleh, metadata_opts, pt, params, grid_names_p)
  end
  delorean_fn :route_compute_rs, sig: 3 do
    |ruleh, pt, features|
    kl = ruleh["classname"].constantize
    kl.compute_rs(ruleh, pt, features)
  end
  delorean_fn :route_validate_results, sig: [1, 2] do
    |ruleh, reqchk=false|
    kl = ruleh["classname"].constantize
    kl.validate_results(ruleh, reqchk)
  end
  delorean_fn :route_validate_grid_attrs, sig: [2, 3] do
    |ruleh, gridname, addl_attrs=nil|
    kl = ruleh["classname"].constantize
    kl.validate_grid_attrs(ruleh, gridname, addl_attrs)
  end

  def base_compute(params, dgparams=params)
    self.class.base_compute(self_as_hash, params, dgparams)
  end

  def self.get_matches_(pt, attrs, params)
    q = super(pt, attrs.except("rule_dt"), params)
    rule_dt = attrs["rule_dt"]
    q=q.where("start_dt <= ?", rule_dt).
       where("end_dt >= ? OR end_dt IS NULL", rule_dt) if rule_dt
    #puts q.to_sql
    q
  end

  def self.get_grid_rename_handler(klass)
    Proc.new do |old, new|
      klass.where(obsoleted_dt: 'infinity').each do |r|
        r.grids.each { |k, v| r.grids[k] = new if v == old }
        r.results.each { |k, v| r.results[k] = %Q("#{new}") if
                         k.ends_with?("_grid") && r.fixed_results[k] == old }
        r.save! if r.changed?
      end
    end
  end

  def self.inherited(child_class)
    super
    Marty::DataGrid.register_rule_handler(get_grid_rename_handler(child_class))
  end
end
