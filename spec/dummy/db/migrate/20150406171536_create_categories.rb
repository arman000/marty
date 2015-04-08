class CreateCategories < ActiveRecord::Migration
  def up
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

    McflyMigration.new.create_table 'gemini_loan_programs' do |t|
      t.string   "name",                                                                   null: false
      t.integer  "amortization_type_id",                                                   null: false
      t.integer  "mortgage_type_id",                                                       null: false
      t.boolean  "conforming",                                             default: true,  null: false
      t.numrange "ltv_ratio_percent_range"
      t.boolean  "high_balance_indicator",                                 default: false, null: false
      t.integer  "loan_amortization_period_count",                         default: 360,   null: false
      t.integer  "streamline_type_id"
      t.integer  "extra_feature_type_id"
      t.integer  "arm_initial_reset_period_count"
      t.decimal  "arm_initial_cap_percent",        precision: 7, scale: 4
      t.decimal  "arm_periodic_cap_percent",       precision: 7, scale: 4
      t.decimal  "arm_lifetime_cap_percent",       precision: 7, scale: 4
      t.integer  "arm_index_type_id"
      t.decimal  "arm_margin_rate_percent",        precision: 7, scale: 4
    end
    McflyMigration.new.add_sql 'gemini_loan_programs', false

    create_table 'gemini_amortization_types' do |t|
      t.string "name", null: false
    end

    create_table 'gemini_mortgage_types' do |t|
      t.string "name", null: false
    end

    create_table 'gemini_streamline_types' do |t|
      t.string "name", null: false
    end
  end

  def down
    drop_table 'gemini_bud_categories'
    drop_table 'gemini_fannie_bups'
    drop_table 'gemini_loan_programs'
    drop_table 'gemini_amortization_types'
    drop_table 'gemini_mortgage_types'
    drop_table 'gemini_streamline_types'
  end
end
