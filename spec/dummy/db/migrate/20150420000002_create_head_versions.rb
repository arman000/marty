class CreateHeadVersions < McflyMigration
  include Marty::Migrations

  def change
    table_name = "head_versions"

    create_table table_name do |t|
      t.references :head, null: false
      t.string :version, null: false
      t.text :result_text
    end

    add_mcfly_unique_index Gemini::HeadVersion
  end
end
