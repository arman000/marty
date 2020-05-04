class AddStrictNullModeToDataGrids < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_data_grids, :strict_null_mode, :boolean, null: false, default: false
  end
end
