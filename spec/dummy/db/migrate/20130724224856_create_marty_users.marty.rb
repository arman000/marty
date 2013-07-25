# This migration comes from marty (originally 3)
class CreateMartyUsers < ActiveRecord::Migration
  def change
    create_table :marty_users do |t|
      t.timestamps

      t.string :login, null: false
      t.string :firstname, null: false
      t.string :lastname, null: false
      t.boolean :active, null: false

      # FIXME: It's a hack to have this in here
      t.integer :uuid
    end
  end
end
