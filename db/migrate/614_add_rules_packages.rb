class AddRulesPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :marty_rules_packages do |t|
      t.timestamps null: false

      t.string :name, null: false
      t.text  :script, null: false
      t.datetime :starts_at, null: false
    end

    add_index :marty_rules_packages, [:name, :starts_at], unique: true
  end
end
