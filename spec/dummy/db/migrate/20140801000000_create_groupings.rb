class CreateGroupings < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    table_name = "groupings"

    create_table table_name do |t|
      t.string :name, null: false
    end
  end
end
