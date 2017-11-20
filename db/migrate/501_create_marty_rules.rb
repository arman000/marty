class CreateMartyRules < McflyMigration
  include Marty::Migrations
  def change()
    create_table :marty_rules do |t|
      t.string :name, null: false
      t.jsonb :attrs,            null: false, default: {}
      t.jsonb :simple_guards,    null: false, default: {}
      t.json  :computed_guards,  null: false, default: {}
      t.jsonb :grids,            null: false, default: {}
      t.jsonb :simple_results,   null: false, default: {}
      t.json  :computed_results, null: false, default: {}
    end
    execute(<<-SQL)
       CREATE OR REPLACE FUNCTION to_numrange(val text)
       RETURNS numrange AS
       $BODY$ select numrange(val); $BODY$
       LANGUAGE SQL IMMUTABLE;
    SQL
  end
end
