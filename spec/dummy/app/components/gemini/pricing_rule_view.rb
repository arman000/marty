class Gemini::MyRuleView < Marty::RuleView
  def configure(c)
    super
    c.model = Gemini::MyRule
  end
end
