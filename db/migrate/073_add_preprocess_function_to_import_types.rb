class AddPreprocessFunctionToImportTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :marty_import_types, :preprocess_function, :string, limit: 255
  end
end
