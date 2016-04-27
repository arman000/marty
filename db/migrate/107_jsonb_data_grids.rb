class JsonbDataGrids < ActiveRecord::Migration
  def change
    change_column :marty_data_grids, :metadata, "jsonb USING metadata::text::jsonb"
    change_column :marty_data_grids, :data, "jsonb USING array_to_json(data)::jsonb"
    add_column :marty_data_grids, :data_type, :string, null: true
  end
end
