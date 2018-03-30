class CreateMartyImportTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_import_types do |t|
      t.timestamps null: false

      t.string :name,             null: false, limit: 255
      t.string :db_model_name,    null: false, limit: 255
      t.string :synonym_fields,   limit: 255
      t.string :cleaner_function, limit: 255
    end
  end
end
