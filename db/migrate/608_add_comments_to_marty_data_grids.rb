class AddCommentsToMartyDataGrids < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_data_grids, :comments, :string, limit: nil, array: true, default: [], null: false
  end
end
