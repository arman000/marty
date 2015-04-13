require 'mcfly'

class CreateMartyScripts < McflyMigration
  include Marty::Migrations

  def change
    create_table :marty_scripts do |t|
      t.string :name, null: false, limit: 255
      t.text   :body, null: false
    end

    add_mcfly_index :scripts, :name
  end
end
