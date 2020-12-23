class AddTestUserViews < ActiveRecord::Migration[6.0]
  def up
    execute('CREATE VIEW vw_users AS SELECT login, firstname FROM marty_users;')
    execute('CREATE VIEW vw_extra_users AS SELECT login, firstname, lastname FROM marty_users;')
  end

  def down
    execute('DROP VIEW IF EXISTS vw_users;')
    execute('DROP VIEW IF EXISTS vw_extra_users;')
  end
end
