class AddValidationFunctionToImportTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :marty_import_types, :validation_function, :string, limit: 255
    drop_table :marty_import_synonyms
  end
end
