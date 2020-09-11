class UseCitextForUserLoginColumn < ActiveRecord::Migration[5.1]
  def up
    execute 'CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;'

    Marty::User.update_all('login = LOWER(login)')

    change_column :marty_users, :login, :citext

    add_index :marty_users, :login, unique: true
  end

  def down
    change_column :marty_users, :login, :varchar
    remove_index :marty_users, :login
  end
end
