class AddTimeoutToPromises < ActiveRecord::Migration[4.2]
  def change
    add_column :marty_promises, :timeout, :integer
  end
end
