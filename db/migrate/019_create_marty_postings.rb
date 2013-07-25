require 'marty/migrations'

class CreateMartyPostings < McFlyAppendOnlyMigration
  include Marty::Migrations

  def change
    create_table :marty_postings do |t|
      t.string :name, null: false
      t.references :posting_type, null: false
      t.boolean :is_test, null: false
      t.string :comment, null: false
    end

    add_mcfly_index :marty_postings,
    :name, :posting_type_id, :is_test

    add_fk :postings, :posting_types
  end
end
