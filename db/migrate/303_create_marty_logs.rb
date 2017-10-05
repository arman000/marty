class CreateMartyLogs < ActiveRecord::Migration
  def change
    create_table :marty_logs do |t|
      t.string :message_type, null: false
      t.string :message, null: false
      t.jsonb :details, null: true
      t.datetime :timestamp, null: false
    end
  end
end
