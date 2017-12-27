class CreateLoanPrograms < ActiveRecord::Migration[4.2]
  def up
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
      t.pg_enum  :enum_state, null: true
    end
    McflyMigration.new.add_sql 'gemini_loan_programs', false
  end

  def down
    drop_table 'gemini_loan_programs'
  end
end
