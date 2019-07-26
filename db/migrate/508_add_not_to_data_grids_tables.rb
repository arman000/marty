class AddNotToDataGridsTables < ActiveRecord::Migration[5.1]
  include Marty::Migrations

  TABLES = {
    marty_grid_index_booleans: :btree,
    marty_grid_index_int4ranges: :gist,
    marty_grid_index_integers: :gin,
    marty_grid_index_numranges: :gist,
    marty_grid_index_strings: :gin
  }

  def change
    TABLES.each do |table, index_type|
      add_column table, :not, :boolean, null: false, default: false
      add_index table, [:not, :key]
    end
  end
end
