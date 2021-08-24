class AddRangeToBup < ActiveRecord::Migration[6.0]
  include Marty::Migrations

  def change
    add_column :gemini_fannie_bups,
      :loan_amortization_period_count_range, :numrange, null: true
    add_column :gemini_fannie_bups, :int4range_col, :int4range, null: true
    add_column :gemini_fannie_bups, :int8range_col, :int8range, null: true
    add_column :gemini_fannie_bups, :tsrange_col, :tsrange, null: true
    add_column :gemini_fannie_bups, :tstzrange_col, :tstzrange, null: true
    add_column :gemini_fannie_bups, :daterange_col, :daterange, null: true
  end
end


