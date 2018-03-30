class CreateMartyRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_roles do |t|
      t.string :name, null: false, limit: 255
    end
  end
end
