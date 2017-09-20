class CreateMartyUserRoles < ActiveRecord::Migration[4.2]
  include Marty::Migrations

  def change
    create_table :marty_user_roles do |t|
      t.references :user, null: false
      t.references :role, null: false
    end

    add_fk :marty_user_roles, :marty_users, column: :user_id
    add_fk :marty_user_roles, :marty_roles, column: :role_id
    add_index(:marty_user_roles, [:user_id])
  end
end
