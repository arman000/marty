class MakeGridIndexesNullable < ActiveRecord::Migration[4.2]
  include Marty::Migrations

  def change
    change_column_null(:marty_grid_index_numranges,  :key, true)
    change_column_null(:marty_grid_index_int4ranges, :key, true)
    change_column_null(:marty_grid_index_integers,   :key, true)
    change_column_null(:marty_grid_index_booleans,   :key, true)
  end
end
