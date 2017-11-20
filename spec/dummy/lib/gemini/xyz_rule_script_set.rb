class Gemini::XyzRuleScriptSet < Marty::RuleScriptSet
  def self.node_name
    "NodeXyz"
  end
  def self.body_start
    "import BaseCode\n#{node_name}: BaseCode::BaseCode\n"
  end
end
