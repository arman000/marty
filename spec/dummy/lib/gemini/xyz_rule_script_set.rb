class Gemini::XyzRuleScriptSet < Marty::RuleScriptSet
  def self.node_name
    "NodeXyz"
  end
  def self.body_start
    "import BaseCode\n#{node_name}: BaseCode::BaseCode\n"
  end
  def xyz_code(ruleh)
    write_code(ruleh["computed_guards"].select{|k,_|k.starts_with?("xyz_")})
  end
  def guard_code(ruleh)
    write_code(ruleh["computed_guards"].reject{|k,_|k.starts_with?("xyz_")})
  end
  def get_code(ruleh)
    x = xyz_code(ruleh)
    super + (x.blank? ? '' :
      "XyzNode:\n    xyz_param =? nil\n" + self.class.indent(x))
  end
  def code_section_counts(ruleh)
    super + { xyz: xyz_code(ruleh).count("\n") }
  end
end
