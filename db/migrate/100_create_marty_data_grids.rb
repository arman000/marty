class CreateMartyDataGrids < McflyMigration
  include Marty::Migrations

  def change
    table_name = "marty_data_grids"

    create_table table_name do |t|
      t.string :name, null: false
      # 2-dimensional array which holds grid data
      t.float :data, array: true
      t.column :metadata, :jsonb, using: "metadata::text::jsonb"
      t.string :data_type, null: true
      t.boolean :lenient, null: false, default: false
    end
    
    change_column :marty_data_grids, :data, "jsonb USING array_to_json(data)::jsonb"
  end
end
