class CreateMartyApiConfigs < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_api_configs do |t|
      t.timestamps null: false
      t.string :script, null: false
      t.string :node, null: true
      t.string :attr, null: true
      t.boolean :logged, null: false, default: false
      t.boolean :validated, null: false, default: false
    end
    add_index :marty_api_configs, [:script, :node, :attr], unique: true
  end
end
