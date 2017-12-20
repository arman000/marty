class Gemini::MyRule < Marty::DeloreanRule
  self.table_name = 'gemini_my_rules'

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  cached_mcfly_lookup :lookup_id, sig: 2 do
    |pt, group_id|
    find_by_group_id group_id
  end

  mcfly_validates_uniqueness_of :name, scope: [:start_dt, :end_dt]

  def self.guard_info
    super + {"g_array" => { multi: true, type: :string,
                            enum: Gemini::GuardOne,},
             "g_single" => { type: :string,
                             enum: Gemini::GuardTwo,
                             width: 100},
             "g_string" => { type: :string,
                             values: ["Hi Mom", "abc", "def"],
                             width: 100},
             "g_bool" => { type: :boolean,
                           width: 100},
             "g_range" => { type: :range,
                            width: 100},
             "g_integer" => { type: :integer,
                              width: 100}}
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

end
