class AddEntityIdToMartyApiAuth < McflyMigration
  def change
    add_column :marty_api_auths, :entity_id, :integer, null: true, index: true
  end
end
