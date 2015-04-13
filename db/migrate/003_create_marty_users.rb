class CreateMartyUsers < ActiveRecord::Migration
  def change
    create_table :marty_users do |t|
      t.timestamps

      t.string  :login,     null: false, limit: 255
      t.string  :firstname, null: false, limit: 255
      t.string  :lastname,  null: false, limit: 255
      t.boolean :active,    null: false
    end
  end
end
