class AddSimpleGuardsOptionsToRules < ActiveRecord::Migration[5.1]
  def change
    add_column :gemini_my_rules, :simple_guards_options, :jsonb, null: false, default: {}
    add_column :gemini_xyz_rules, :simple_guards_options, :jsonb, null: false, default: {}

    reversible do |dir|
      dir.up { create_indexes }
    end
  end

  def create_indexes
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

      col = "(simple_guards_options -> '#{field}' -> 'not')"
      sql = <<-SQL
        CREATE INDEX idx_#{table}_#{field}_not ON #{table} USING BTREE
        (#{col});
      SQL

      execute sql
    end
  end
end
