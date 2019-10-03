class AddPromisePriority < ActiveRecord::Migration[4.2]
  def up
    add_column :marty_promises, :priority, :integer
  end

  def down
    remove_column :marty_promises, :priority
  end
end
