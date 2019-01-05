class Gemini::XyzRuleScriptSet < Marty::RuleScriptSet
  def self.script_imports(ruleh)
    ["BaseCode"]
  end
  def self.node_parent(ruleh)
    "BaseCode::BaseCode"
  end
end
