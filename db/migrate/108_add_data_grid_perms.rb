class AddDataGridPerms < ActiveRecord::Migration[4.2]
  def self.up
    default = {
      view: [],
      edit_data: [],
      edit_all: []
    }
    table = :marty_data_grids
    add_column table, :permissions, :jsonb, null: false, default: default
    add_index table, "(permissions->'view')", using: "GIN",
              name: :marty_data_grids_perm_idx
    Marty::Role.create(name: 'data_grid_editor') unless
      Marty::Role.exists?(name: 'data_grid_editor')
  end
  def self.down
    remove_column :marty_data_grids, :permissions
    Marty::Role.find_by(name: 'data_grid_editor').destroy
  end
end
