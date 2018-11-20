class AddQueueToMartyPromises < ActiveRecord::Migration[4.2]
  def change
    add_column :marty_promises, :queue, :string
  end
end
