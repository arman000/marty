class AddRuleIndices < ActiveRecord::Migration
  def change
    execute(<<-SQL)
    CREATE INDEX idx_rule_g_array ON marty_rules USING GIN
       ((simple_guards->'g_array'));
    CREATE INDEX idx_rule_g_single ON marty_rules USING BTREE
       ((simple_guards->'g_single'));
    CREATE INDEX idx_rule_g_integer ON marty_rules USING BTREE
       ((simple_guards->'g_integer'));
    CREATE INDEX idx_rule_g_string ON marty_rules USING BTREE
       ((simple_guards->'g_string'));
    CREATE INDEX idx_rule_g_range ON marty_rules USING GIST
       ((to_numrange(simple_guards->>'g_range')));
    SQL
  end
end
