class CreateGeminiMyRules < McflyMigration
  include Marty::Migrations
  def change()
    create_table :gemini_my_rules do |t|
      t.string :name, null: false
      t.column :rule_type, :my_rule_type, null: false
      t.datetime :start_dt, null: false
      t.datetime :end_dt, null: true
      t.string :engine, null: false, default: 'Gemini::MyRuleScriptSet'
      t.boolean :other_flag
      t.jsonb :simple_guards,    null: false, default: {}
      t.json  :computed_guards,  null: false, default: {}
      t.jsonb :grids,            null: false, default: {}
      t.json  :results,          null: false, default: {}
      t.jsonb :fixed_results,    null: false, default: {}
    end
    execute("CREATE OR REPLACE FUNCTION to_numrange(val text) "\
            "RETURNS numrange AS "\
            "$BODY$ select numrange(val); $BODY$ "\
            "LANGUAGE SQL IMMUTABLE;")
   end
end
