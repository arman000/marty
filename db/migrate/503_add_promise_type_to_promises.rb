class AddPromiseTypeToPromises < ActiveRecord::Migration[4.2]
  def up
    add_column :marty_promises, :promise_type, :marty_promise_types

    Marty::Promise.update_all(promise_type: 'delorean')

    change_column :marty_promises, :promise_type, :marty_promise_types, null: false
  end

  def down
    remove_column :marty_promises, :promise_type
  end
end
