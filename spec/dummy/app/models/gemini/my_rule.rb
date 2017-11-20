class Gemini::MyRule < Marty::Rule

  before_validation do
    self.attrs ||= {}
    self.attrs['type'] = 'MyRule'
    self.attrs['engine'] = 'Gemini::RuleScriptSet'
  end

  def self.attr_info
    h = super
    h["subtype"][:enum] = Gemini::RuleSubType
    h["other_flag"] = {type: :boolean, width: 50}
    h
  end

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

  def self.default_scope
    where("attrs->>'type' = 'MyRule'")
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

end
