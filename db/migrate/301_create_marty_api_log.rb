class CreateMartyApiLog < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_api_logs do |t|
      t.string :script, null: false
      t.string :node, null: false
      t.string :attrs, null: false
      t.json :input, null: true
      t.json :output, null: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :error, null: true
      t.string :remote_ip, null: false
      t.string :auth_name, null: true
    end
  end
end
