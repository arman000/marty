class Marty::SqlRuleView < Marty::BaseRuleView
  include Marty::Extras::Layout

  def self.klass
    Marty::SqlRule
  end

  def self.base_fields
    super + [:rule_type, :expression, :start_dt, :end_dt]
  end

  attribute :start_dt do |c|
    c.width = 150
    c.format = 'Y-m-d H:i'
  end

  attribute :end_dt do |c|
    c.width = 150
    c.format = 'Y-m-d H:i'
  end

  attribute :rule_type do |c|
    c.width = 200
  end

  attribute :expression do |c|
    c.flex = 1
  end

end
