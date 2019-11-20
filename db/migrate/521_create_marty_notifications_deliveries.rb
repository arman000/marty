class CreateMartyNotificationsDeliveries < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_notifications_deliveries do |t|
      t.integer :notification_id, null: false
      t.integer :recipient_id
      t.string :delivery_type, null: false
      t.string :state, null: false
      t.text :text, null: false, default: ''
      t.string :error_text, null: false, default: ''

      t.timestamps null: false
    end

    add_foreign_key :marty_notifications_deliveries, :marty_notifications,
                    column: :notification_id, on_delete: :cascade
    add_foreign_key :marty_notifications_deliveries, :marty_users,
                    column: :recipient_id, on_delete: :nullify

    add_index :marty_notifications_deliveries, [:notification_id, :recipient_id, :delivery_type],
              unique: true, name: :index_marty_notifications_deliveries_on_n_id_r_id_and_type
  end
end
