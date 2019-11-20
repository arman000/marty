class CreateMartyNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_notifications do |t|
      t.pg_enum :event_type, enum: :marty_notifications_event_types, null: false
      t.string :state, null: false
      t.text :text, null: false

      t.timestamps null: false
    end
  end
end
