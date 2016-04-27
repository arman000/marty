class CreateMartyDataGrids < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    table_name = "marty_data_grids"

    # drop deprecated versions and dependent tables
    execute("DROP TABLE IF EXISTS gemini_llpas")
    execute("DROP TABLE IF EXISTS gemini_llpa_types")
    execute("DROP FUNCTION IF EXISTS gemini_llpas_update()")
    execute("DROP FUNCTION IF EXISTS gemini_llpas_insert()")
    execute("DROP FUNCTION IF EXISTS gemini_llpas_delete()")

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.string :name, null: false
      # 2-dimensional array which holds grid data
      t.float :data, array: true
      t.column :metadata, :json
    end
  end
end
