class CreateMartyNotificationsConfig < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_notifications_configs do |t|
      t.pg_enum :event_type, enum: :marty_notifications_event_types, null: false
      t.integer :recipient_id
      t.string :delivery_type, null: false
      t.string :state, null: false
      t.text :text, null: false, default: ''

      t.timestamps null: false
    end

    add_foreign_key :marty_notifications_configs, :marty_users,
                    column: :recipient_id, on_delete: :nullify

    add_index :marty_notifications_configs,
      [:event_type, :recipient_id, :delivery_type],
      unique: true,
      name: :index_marty_notifications_configs_on_event_recipient_delivery
  end
end
