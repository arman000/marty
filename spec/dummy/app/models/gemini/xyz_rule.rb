class Gemini::XyzRule < Marty::Rule

  before_validation do
    self.attrs ||= {}
    self.attrs['type'] = 'XyzRule'
    self.attrs['engine'] = 'Gemini::XyzRuleScriptSet'
  end

  def self.attr_info
    h = super
    h["subtype"][:enum] = Gemini::XyzRuleSubType
    h["subtype"][:label] = "Rule Type"
    h
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
                              width: 100},
             "g_range1" => { type: :range,
                              width: 100},
             "g_range2" => { type: :range,
                              width: 100},
             "g_integer" => { type: :integer,
                              width: 100}
    }
  end

  def self.default_scope
    where("attrs->>'type' = 'XyzRule'")
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end


end
