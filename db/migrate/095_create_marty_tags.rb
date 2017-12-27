class CreateMartyTags < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    create_table :marty_tags do |t|
      t.string :name,    null: false, limit: 255
      t.string :comment, null: false, limit: 255
    end

    add_mcfly_index :marty_tags, :name
  end
end
