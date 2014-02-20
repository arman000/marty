require 'marty/migrations'

class CreateMartyTags < McflyAppendOnlyMigration
  include Marty::Migrations

  def change
    create_table :marty_tags do |t|
      t.string :name, null: false
      t.string :comment, null: false
    end

    add_mcfly_index :marty_tags, :name
  end
end
