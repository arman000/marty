class MigrateMartyRolesToEnum < ActiveRecord::Migration[5.1]
  include Marty::Migrations

  def up
    new_enum(Marty::RoleType, 'keep_marty_prefix_here')

    add_column :marty_user_roles, :role, :marty_role_types
    add_column :marty_import_types, :role, :marty_role_types

    execute <<-SQL
      UPDATE marty_user_roles AS ur
      SET role = roles.name::marty_role_types
      FROM marty_roles AS roles
      WHERE ur.role_id = roles.id
    SQL

    execute <<-SQL
      UPDATE marty_import_types AS it
      SET role = roles.name::marty_role_types
      FROM marty_roles AS roles
      WHERE it.role_id = roles.id
    SQL

    remove_column :marty_user_roles, :role_id
    remove_column :marty_import_types, :role_id

    drop_table :marty_roles

    change_column_null :marty_user_roles, :role, false
    change_column_null :marty_import_types, :role, false
  end

  def down
    create_table :marty_roles do |t|
      t.string :name, null: false, limit: 255
    end

    add_column :marty_user_roles, :role_id, :integer
    add_column :marty_import_types, :role_id, :integer

    Marty::RoleTypeDelegator.values.each do |role|
      Marty::Role.create!(name: role)
    end

    execute <<-SQL
      UPDATE marty_user_roles AS ur
      SET role_id = roles.id
      FROM marty_roles AS roles
      WHERE ur.role::text = roles.name
    SQL

    execute <<-SQL
      UPDATE marty_import_types AS ur
      SET role_id = roles.id
      FROM marty_roles AS roles
      WHERE ur.role::text = roles.name
    SQL

    remove_column :marty_user_roles, :role
    remove_column :marty_import_types, :role

    execute <<-SQL
      DROP TYPE marty_role_types
    SQL

    change_column_null :marty_user_roles, :role_id, false
    change_column_null :marty_import_types, :role_id, false

    add_fk :marty_user_roles, :marty_roles, column: :role_id
    add_fk :marty_import_types, :marty_roles, column: :role_id
  end
end
