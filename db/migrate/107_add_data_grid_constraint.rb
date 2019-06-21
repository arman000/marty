class AddDataGridConstraint < ActiveRecord::Migration[4.2]
  def self.up
    add_column :marty_data_grids, :constraint, :string, null: true
  end
  def self.down
    remove_column :marty_data_grids, :constraint
  end
end
