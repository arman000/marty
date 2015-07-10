class AddPreprocessFunctionToImportTypes < ActiveRecord::Migration
  def change
    add_column :marty_import_types, :preprocess_function, :string, limit: 255
  end
end
