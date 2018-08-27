class Marty::SqlRule < Marty::BaseRule
  self.abstract_class = true

  def self.generate_exclusions(attr_mdl, rule_type)
    exclusions = []

    self.where(rule_type: rule_type).each do |rule|
      executions_affected = []
      rule_attrs = attr_mdl.where(rule_id: rule.id)
      rule_attrs.each do |attr|
        executions_affected.append(self.generate_executions_affected(attr))
      end

      executions_empty = executions_affected.all? {|x| x == []}
      if !executions_empty
        exclusions.append({rule.id => executions_affected.flatten})
      end
    end

    Marty::Exclusion.new(exclusions)
  end

end
