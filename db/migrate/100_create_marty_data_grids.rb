class CreateMartyDataGrids < McflyMigration[4.2]
  include Marty::Migrations

  def change
    table_name = "marty_data_grids"

    create_table table_name do |t|
      t.string :name, null: false
      # 2-dimensional array which holds grid data
      t.jsonb :data
      t.jsonb :metadata
      t.string :data_type, null: true
      t.boolean :lenient, null: false, default: false
    end
  end
end
