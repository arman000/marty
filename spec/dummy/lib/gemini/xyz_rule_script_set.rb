class Gemini::XyzRuleScriptSet < Marty::RuleScriptSet
  def self.node_name
    "NodeXyz"
  end
  def self.body_start
    "import BaseCode\n#{node_name}: BaseCode::BaseCode\n"
  end
  def xyz_code(rule)
    write_code(rule.computed_guards.select{|k,_|k.starts_with?("xyz_")})
  end
  def guard_code(rule)
    write_code(rule.computed_guards.reject{|k,_|k.starts_with?("xyz_")})
  end
  def get_code(rule)
    x = xyz_code(rule)
    super + (x.blank? ? '' :
      "XyzNode:\n    xyz_param =? nil\n" + self.class.indent(x))
  end
  def code_section_counts(rule)
    super + { xyz: xyz_code(rule).count("\n") }
  end
  def self.rule_pfx
    "XYZRULE"
  end
end
