class AddIndexesToHttpApiAuths < McflyMigration

  def up
    add_index :marty_http_api_auths, [:obsoleted_dt, :token], unique: true
  end

  def down
    remove_index :marty_http_api_auths, [:obsoleted_dt, :token]
  end
end
