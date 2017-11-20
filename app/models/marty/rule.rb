class Marty::Rule < Marty::BaseRule

  def self.attr_info
    super + {"type"     => {type: :string, hidden: true},
             "subtype"  => {type: :string, width: 100, required: true},
             "start_dt" => {type: :datetime,   width: 150},
             "end_dt"   => {type: :datetime,   width: 150},
             "engine"   => {type: :string, hidden: true},
    }
  end

  def self.get_matches_(pt, attrs, params)
    q = super(pt, attrs.except("rule_dt"), params)
    rule_dt = attrs["rule_dt"]
    q=q.where("(attrs->>'start_dt')::timestamp <= ?", rule_dt).
       where("(attrs->>'end_dt')::timestamp >= ? OR attrs->>'end_dt'"\
             " IS NULL", rule_dt) if rule_dt
    #puts q.to_sql
    q.order("(attrs->>'start_dt')::timestamp DESC NULLS LAST")
  end

  mcfly_lookup :get_matches, sig: 3 do
    |pt, attrs, params|
    get_matches_(pt, attrs, params)
  end

end
