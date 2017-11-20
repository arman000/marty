class Gemini::RuleScriptSet < Marty::RuleScriptSet
  def self.node_name
    "Node2"
  end
  def self.body_start
    params = <<~END
    param1 =?
    param2 =?
    paramb =? false
    END
    super + indent(params)
  end
end
