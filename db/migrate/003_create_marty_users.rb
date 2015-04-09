class CreateMartyUsers < ActiveRecord::Migration
  def change
    create_table :marty_users do |t|
      t.timestamps

      t.string :login, null: false
      t.string :firstname, null: false
      t.string :lastname, null: false
      t.boolean :active, null: false
    end
  end
end
