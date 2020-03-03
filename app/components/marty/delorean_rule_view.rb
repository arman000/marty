class Marty::DeloreanRuleView < Marty::BaseRuleView
  include Marty::Extras::Layout

  def self.klass
    Marty::DeloreanRule
  end

  def self.base_fields
    fields = if klass&.column_names&.include?('rule_type')
               [:rule_type, :start_dt, :end_dt]
             else
               [:start_dt, :end_dt]
             end

    super + fields
  end

  attribute :rule_type do |c|
    c.width = 200
  end

  attribute :start_dt do |c|
    c.width = 150
    c.format = 'Y-m-d H:i'
  end

  attribute :end_dt do |c|
    c.width = 150
    c.format = 'Y-m-d H:i'
  end
end
