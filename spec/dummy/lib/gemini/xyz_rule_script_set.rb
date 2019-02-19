class Gemini::XyzRuleScriptSet < Marty::RuleScriptSet
  def self.node_name
    "NodeXyz"
  end
  def self.body_start
    "import BaseCode\n#{node_name}: BaseCode::BaseCode\n"
  end
  def xyz_header
    "XyzNode:\n    xyz_param =? nil\n"
  end
  def xyz_code(ruleh)
    c = write_code(ruleh["computed_guards"].select{|k,_|k.starts_with?("xyz_")})
    c.blank? ? '' : self.class.indent(c)
  end
  def guard_code(ruleh)
    write_code(ruleh["computed_guards"].reject{|k,_|k.starts_with?("xyz_")})
  end
  def get_code(ruleh)
    x = xyz_code(ruleh)
    super +
      xyz_header +
      xyz_code(ruleh)
  end
  def code_section_counts(ruleh)
    super + { xyz_header: xyz_header.count("\n"),
              xyz: xyz_code(ruleh).count("\n") }
  end
end
