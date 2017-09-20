class CreateMartyGridIndexBooleans < ActiveRecord::Migration[4.2]
  include Marty::Migrations

  def change
    table_name = "marty_grid_index_booleans"

    # drop deprecated version
    execute("DROP TABLE IF EXISTS #{table_name}")

    create_table table_name do |t|
      t.datetime :created_dt, null: false
      t.references :data_grid, null: false
      t.string :attr, null: false
      t.boolean :key, null: false
      t.integer :index, null: false
    end

    # FIXME: not sure if this index is appropriate for our queries.
    # May need to break it up.
    add_index table_name,
    [:created_dt, :data_grid_id, :attr],
    name: "index_#{table_name}"
    add_index table_name, :key

    add_fk table_name, :data_grids
  end
end
