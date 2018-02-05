class AddRuleIndices < ActiveRecord::Migration[4.2]
  def change
    ['gemini_my_rules',  'g_array',    :array,
     'gemini_my_rules',  'g_single',   :scalar,
     'gemini_my_rules',  'g_string',   :scalar,
     'gemini_my_rules',  'g_bool',     :scalar,
     'gemini_my_rules',  'g_integer',  :scalar,
     'gemini_my_rules',  'g_range',    :range,
     'gemini_xyz_rules', 'flavors',    :array,
     'gemini_xyz_rules', 'guard_two',  :scalar,
     'gemini_xyz_rules', 'g_date',     :scalar,
     'gemini_xyz_rules', 'g_datetime', :scalar,
     'gemini_xyz_rules', 'g_bool',     :scalar,
     'gemini_xyz_rules', 'g_integer',  :scalar,
     'gemini_xyz_rules', 'g_range1',   :range,
     'gemini_xyz_rules', 'g_range2',   :range,
    ].in_groups_of(3).each do |table, field, type|
      index = { array: "GIN",
                scalar: "BTREE",
                range: "GIST" }[type]
      case type
      when :array, :scalar
        col="(simple_guards->'#{field}')"
      when :range
        col="(to_numrange(simple_guards->>'#{field}'))"
      end
      sql =<<-SQL
        CREATE INDEX idx_#{table}_#{field} ON #{table} USING #{index}
        (#{col});
      SQL
      execute sql
    end
  end
end
