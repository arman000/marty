# This migration comes from marty (originally 69)
class CreateMartyImportSynonyms < ActiveRecord::Migration
  include Marty::Migrations

  def change
    create_table :marty_import_synonyms do |t|
      t.timestamps

      t.references 	:import_type, null: false
      t.string		:synonym, null: false
      t.string		:internal_name, null: false
    end

    add_fk :import_synonyms, :import_types
  end
end
