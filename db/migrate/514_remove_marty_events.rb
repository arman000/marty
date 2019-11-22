class RemoveMartyEvents < ActiveRecord::Migration[4.2]
  def up
    drop_table :marty_events

    execute <<-SQL
      DROP TYPE IF EXISTS enum_event_operations;
    SQL
  end

  def down
    announce("No-op on RemoveMartyEvents.down")
  end
end
