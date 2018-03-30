class CreateCategories < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Migration[4.2].new.create_table 'entities' do |t|
      t.string :name
    end
    McflyAppendOnlyMigration.new.create_table 'gemini_bud_categories' do |t|
      t.string :name
    end
    McflyAppendOnlyMigration.new.add_sql 'gemini_bud_categories', false

    McflyMigration.new.create_table 'gemini_fannie_bups' do |t|
      t.integer  "entity_id"
      t.integer  "bud_category_id",                         null: false
      t.decimal  "note_rate",       precision: 7, scale: 4, null: false
      t.integer  "settlement_mm",                           null: false
      t.integer  "settlement_yy",                           null: false
      t.float    "buy_up",                                  null: false
      t.float    "buy_down",                                null: false
    end
    McflyMigration.new.add_sql 'gemini_fannie_bups', false
  end

  def down
    drop_table 'gemini_bud_categories'
    drop_table 'gemini_fannie_bups'
  end
end
