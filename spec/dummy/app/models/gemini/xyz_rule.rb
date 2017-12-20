class Gemini::XyzRule < Marty::DeloreanRule
  self.table_name = 'gemini_xyz_rules'

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  cached_mcfly_lookup :lookup_id, sig: 2 do
    |pt, group_id|
    find_by_group_id group_id
  end

  mcfly_validates_uniqueness_of :name, scope: [:start_dt, :end_dt]

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
                              width: 100},
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


end
