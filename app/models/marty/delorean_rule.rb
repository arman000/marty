class Marty::DeloreanRule < Marty::BaseRule
  self.abstract_class = true

  validates_presence_of :rule_type, :start_dt

  def validate
    super
    return errors[:base] << 'Start date must be before end date' if
      start_dt && end_dt && start_dt >= end_dt

    if computed_guards.present? || results.present?
      begin
        eclass = engine && engine.constantize || Marty::RuleScriptSet
        eng = eclass.new('infinity').get_engine(self_as_hash)
      rescue StandardError => e
        return errors[:computed] << '- ' + e.message
      end
    end
  end

  def self_as_hash
    attributes + { 'classname' => self.class.name }
  end

  def self.find_fixed(results)
    results.each_with_object({}) do |(k, v), h|
      v_wo_comment = /\A([^#]+)/.match(v)[1] if v.include?('#')
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
    self.fixed_results = self.class.find_fixed(results)
  end

  def self.results_cfg_var
    'NOT DEFINED'
  end

  def self.compg_keys(computed_guards)
    computed_guards.keys
  end

  def self.comp_res_keys(results, grids, ecl, pcfg)
    # FIXME in May 2019: remove this check (use as passed)
    defkeys = pcfg.is_a?(Hash) ? pcfg.keys : pcfg
    results.keys.map { |k| k.ends_with?('_grid') ? ecl.grid_final_name(k) : k }.
       select { |k| defkeys.include?(k) } + grid_keys(grids, ecl)
  end

  def self.grid_keys(grids, eclass)
      grids.keys.map { |k| eclass.grid_final_name(k) }
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

  def self.base_compute2(ruleh, metadata_opts, params, dgparams = params)
      id, name, eclassname, computed_guards, grids, results, fixed_results =
        ruleh.values_at('id', 'name', 'engine', 'computed_guards', 'grids',
                        'results', 'fixed_results')
      raise "Error in rule '#{id}:#{name}': bad metadata_opts" if !metadata_opts

      eclass = eclassname && eclassname.constantize || Marty::RuleScriptSet
      engine = eclass.new(params['pt']).get_engine(ruleh) if
        computed_guards.present? || results.present?

      result = OpenStruct.new(cg_keys: compg_keys(computed_guards))

      if computed_guards.present?
        begin
          result.cg_vals = engine.evaluate(eclass.node_name, result.cg_keys,
                                           params.clone)
        rescue StandardError => e
          result.err_message = e.message
          result.err_stack   = e.backtrace
          result.err_section = 'computed_guards'
          raise ComputeError.new(
            "Error (guard) in rule '#{id}:#{name}': #{result.err_message}",
            result.err_stack,
            params.clone,
            result.err_section)
        end
        result.cg_hash = Hash[result.cg_keys.zip(result.cg_vals)]
        fails = result.cg_hash.select { |k, v| ![v].flatten.first }
        return fails if fails.present?
      end

      grids_computed = false
      result.gr_keys = grid_keys(grids, eclass)
      result.res_keys = comp_res_keys(results, grids, eclass, metadata_opts)
      if (result.res_keys - result.gr_keys - fixed_results.keys).present?
        begin
          result.res_vals = engine.evaluate(
            eclass.node_name,
            result.res_keys,
            params + {
              'dgparams__' => dgparams,
            })
          grids_computed = true
        rescue StandardError => e
          result.err_message = e.message
          result.err_stack   = e.backtrace
          result.err_section = 'results'
          raise ComputeError.new(
            "Error (results) in rule '#{id}:#{name}': #{result.err_message}",
            result.err_stack,
            params + {
              'dgparams__' => dgparams,
            },
            result.err_section)
        end
        result.res_hash = Hash[result.res_keys.zip(result.res_vals)]
      else
        result.res_hash = fixed_results.slice(*result.res_keys)
      end

      if grids.present? && !grids_computed
        pt = params['pt']
        gres = {}
        result.gr_hash = grids.each_with_object({}) do |(gvar, gname), h|
          usename = eclass.grid_final_name(gvar)
          next h[usename] = gres[gname] if gres[gname]

          dg = Marty::DataGrid.lookup_h(pt, gname)
          dgr = dg && Marty::DataGrid.lookup_grid_distinct_entry_h(pt, dgparams,
                                                                   dg)
          h[usename] = gres[gname] = dgr['result'] if dgr
        end
      end
      (result.res_hash || {}) + (result.gr_hash || {})
  ensure
      if ruleh['fixed_results']['log__']
        resh = result.to_h
        [:res_keys, :res_vals].each { |k| resh.delete(k) } if
          result.res_hash.present? || result.res_keys.blank?
        [:cg_keys, :cg_vals].each { |k| resh.delete(k) } if
          result.cg_hash.present? ||  result.cg_keys.blank?
        resh.delete(:gr_keys) if result.gr_hash.present? || result.gr_keys.blank?
        estack_full = resh.delete(:err_stack)
        estack = estack_full && {
          err_stack: estack_full.select { |l| l.starts_with?('DELOREAN') } } || {}
        detail = { input: params, dgparams: dgparams } + resh + estack
        Marty::Logger.info("Rule Log #{ruleh['name']}",
                           Marty::Util.scrub_obj(detail))
      end
  end

  delorean_fn :route_compute, sig: 4 do |ruleh, pt, params, grid_names_p|
    kl = ruleh['classname'].constantize
    kl.compute(ruleh, nil, pt, params, grid_names_p)
  end
  delorean_fn :route_compute2, sig: 5 do |ruleh, metadata_opts, pt, params, grid_names_p|
    kl = ruleh['classname'].constantize
    kl.compute(ruleh, metadata_opts, pt, params, grid_names_p)
  end
  delorean_fn :route_compute_rs, sig: 3 do |ruleh, pt, features|
    kl = ruleh['classname'].constantize
    kl.compute_rs(ruleh, pt, features)
  end
  delorean_fn :route_validate_results, sig: [1, 2] do |ruleh, reqchk = false|
    kl = ruleh['classname'].constantize
    kl.validate_results(ruleh, reqchk)
  end
  delorean_fn :route_validate_grid_attrs, sig: [2, 3] do |ruleh, gridname, addl_attrs = nil|
    kl = ruleh['classname'].constantize
    kl.validate_grid_attrs(ruleh, gridname, addl_attrs)
  end

  def base_compute2(metadata_opts, params, dgparams = params)
    self.class.base_compute2(self_as_hash, metadata_opts, params, dgparams)
  end

  def self.get_matches_(pt, attrs, params)
    q = super(pt, attrs.except('rule_dt'), params)
    rule_dt = attrs['rule_dt']
    q = q.where('start_dt <= ?', rule_dt).
       where('end_dt >= ? OR end_dt IS NULL', rule_dt) if rule_dt
    # puts q.to_sql
    q
  end

  def self.get_grid_rename_handler(klass)
    proc do |old, new|
      klass.where(obsoleted_dt: 'infinity').each do |r|
        r.grids.each { |k, v| r.grids[k] = new if v == old }
        r.results.each do |k, v|
          r.results[k] = %Q("#{new}") if
                         k.ends_with?('_grid') && r.fixed_results[k] == old
        end
        r.save! if r.changed?
      end
    end
  end

  def self.inherited(child_class)
    super
    Marty::DataGrid.register_rule_handler(get_grid_rename_handler(child_class))
  end
end
