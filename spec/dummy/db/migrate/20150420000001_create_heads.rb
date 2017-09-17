class CreateHeads < McflyMigration[4.2]
  include Marty::Migrations

  def change
    table_name = "heads"

    create_table table_name do |t|
      t.string :name, null: false
      t.text :condition_text
    end

    add_mcfly_unique_index Gemini::Head
  end
end
