class CreateGroupingHeadVersions < McflyMigration[4.2]
  include Marty::Migrations

  def change
    table_name = "grouping_head_versions"

    create_table table_name do |t|
      t.references :grouping, null: false
      t.references :head_version, null: false
    end
  end
end
