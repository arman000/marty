class CreateMartyRoles < ActiveRecord::Migration
  def change
    create_table :marty_roles do |t|
      t.string :name, null: false, limit: 255
    end
  end
end
