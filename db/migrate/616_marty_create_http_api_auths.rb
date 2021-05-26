    
class MartyCreateHttpApiAuths < McflyMigration

  def up
    create_table :marty_http_api_auths do |t|
      t.string :app_name, null: false
      t.string :token, null: false
      t.jsonb :authorizations, default: []
    end
  end

  def down
    drop_table :marty_http_auths
  end
end



