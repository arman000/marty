class Gemini::MyRuleScriptSet < Marty::RuleScriptSet
  def self.params_extra_code(ruleh)
    params = <<~END
    param1 =?
    param2 =?
    paramb =? false
    END
  end
end
