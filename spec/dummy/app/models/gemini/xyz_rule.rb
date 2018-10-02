class Gemini::XyzRule < Marty::DeloreanRule
  self.table_name = 'gemini_xyz_rules'

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  cached_mcfly_lookup :lookup_id, sig: 2 do
    |pt, group_id|
    find_by_group_id group_id
  end

  mcfly_validates_uniqueness_of :name

  def self.results_cfg_var
    'RULEOPTS_XYZ'
  end
  def self.guard_info
    super + {"flavors" => { multi: true, type: :string,
                            enum: Gemini::XyzEnum,
                            width: 150},
             "guard_two" => { type: :string,
                              enum: Gemini::GuardTwo,
                              width: 100},
             "g_date" => { type: :date },
             "g_datetime" => { type: :datetime },
             "g_string" => { type: :string,
                              width: 100},
             "g_bool" => { type: :boolean,
                           width: 100,
                           null: false},
             "g_range1" => { type: :range,
                              width: 100},
             "g_range2" => { type: :range,
                              width: 100},
             "g_integer" => { type: :integer,
                              width: 100}
    }
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

  def compute(*args)
    base_compute2(*args)
  end
  def compute_xyz(pt, xyz_param)
    # Given a set of parameters, compute the RULE adjustment.  Returns
    # {} if precondition is not met.

    xyz_keys =  computed_guards.select{|k,_|k.starts_with?("xyz_")}.keys
    return {} unless xyz_keys.present?

    eclass = engine && engine.constantize || Marty::RuleScriptSet
    engine = eclass.new(pt).get_engine(self_as_hash)
    res = engine.evaluate("XyzNode", xyz_keys, {"xyz_param"=>xyz_param})

    res.all?
  end
end
