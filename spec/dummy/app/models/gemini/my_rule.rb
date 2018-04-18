class Gemini::MyRule < Marty::DeloreanRule
  self.table_name = 'gemini_my_rules'

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  cached_mcfly_lookup :lookup_id, sig: 2 do
    |pt, group_id|
    find_by_group_id group_id
  end

  mcfly_validates_uniqueness_of :name

  def self.guard_info
    super + {"g_array" => { multi: true, type: :string,
                            enum: Gemini::GuardOne,},
             "g_single" => { type: :string,
                             enum: Gemini::GuardTwo,
                             width: 100},
             "g_string" => { type: :string,
                             values: ["Hi Mom", "abc", "def", "zzz"],
                             width: 100},
             "g_bool" => { type: :boolean,
                           width: 100,
                           null: false},
             "g_nullbool" => { type: :boolean,
                           width: 100},
             "g_range" => { type: :range,
                            width: 100},
             "g_integer" => { type: :integer,
                              width: 100},
             "g_has_default" => { type:  :string,
                                  default: "string default"},
             "g_bool_def" => { type: :boolean,
                               width: 100,
                               default: true,
                               null: false},
             "g_nbool_def" => { type: :boolean,
                                default: false,
                               width: 100},
    }
  end
  def self.results_cfg_var
    'RULEOPTS_MYRULE'
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

  def compute(*args)
    base_compute(*args)
  end
end
