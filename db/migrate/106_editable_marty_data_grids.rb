class EditableMartyDataGrids < McflyMigration
  include Marty::Migrations

  def change
    table_name = "marty_data_grids"

    disable_triggers(table_name) do
      add_sql(table_name, false)
    end

    # reindex DataGrids since the index tables were recreated.
    Marty::DataGrid.all.each { |dg| dg.build_index }
  end
end
