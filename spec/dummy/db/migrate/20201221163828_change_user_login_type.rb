class ChangeUserLoginType < ActiveRecord::Migration[6.0]
  include Marty::Migrations

  # migration is needed to make sure that recreate_views works as intended
  def up
    recreate_views('vw_users', 'vw_extra_users') do
      change_column :marty_users, :login, :varchar
      change_column :marty_users, :login, :citext
    end

    execute("SELECT * FROM vw_users").to_a
  end

  def down
    recreate_views('vw_users', 'vw_extra_users') do
      change_column :marty_users, :login, :citext
    end
  end
end
