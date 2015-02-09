# This migration comes from marty (originally 68)
class CreateMartyImportTypes < ActiveRecord::Migration
  def change
    create_table :marty_import_types do |t|
      t.timestamps

      t.string  :name, null: false
      t.string  :db_model_name, null: false
      t.string  :synonym_fields
      t.string  :cleaner_function
    end
  end
end
