class CreateMartyImportSynonyms < ActiveRecord::Migration
  include Marty::Migrations

  def change
    create_table :marty_import_synonyms do |t|
      t.timestamps

      t.references :import_type,   null: false
      t.string     :synonym,       null: false, limit: 255
      t.string     :internal_name, null: false, limit: 255
    end

    add_fk :import_synonyms, :import_types
  end
end
