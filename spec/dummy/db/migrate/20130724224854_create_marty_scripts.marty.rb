# This migration comes from marty (originally 1)
require 'mcfly'

class CreateMartyScripts < McFlyMigration
  include Marty::Migrations

  def change
    create_table :marty_scripts do |t|
      t.string 		:name, 		null: false
      t.text 		:body, 		null: false
      t.string 		:version, 	null: false
      t.text 		:logmsg, 	null: false
    end

    add_mcfly_index :scripts, :name
  end
end
