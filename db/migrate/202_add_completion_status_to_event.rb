class AddCompletionStatusToEvent < ActiveRecord::Migration
  def change
    add_column :marty_events, :error, :boolean, null: true
    execute "update marty_events set error = 'f'"
  end
end
