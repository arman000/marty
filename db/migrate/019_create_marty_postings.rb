class CreateMartyPostings < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    create_table :marty_postings do |t|
      t.string     :name,         null: false, limit: 255
      t.references :posting_type, null: false
      t.string     :comment,      null: false, limit: 255
    end

    add_mcfly_index :marty_postings,
    :name, :posting_type_id

    add_fk :postings, :posting_types
  end
end
