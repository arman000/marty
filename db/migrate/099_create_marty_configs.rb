class CreateMartyConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_configs do |t|
      t.timestamps null: false

      t.string :key, null: false
      t.jsonb :value, null: false
      t.text :description
    end
    add_index :marty_configs, :key, unique: true
  end
end
