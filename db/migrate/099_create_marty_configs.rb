class CreateMartyConfigs < ActiveRecord::Migration
  def change
    create_table :marty_configs do |t|
      t.timestamps null: false

      t.string :key
      t.jsonb :value
      t.text :description
    end
  end
end
