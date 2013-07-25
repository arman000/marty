# This migration comes from marty (originally 2)
class CreateMartyDscripts < ActiveRecord::Migration
  include Marty::Migrations

  def change
    create_table :marty_dscripts do |t|
      t.timestamps

      t.references	:script, 	null: false
      t.text 		:body, 		null: false
      t.references 	:user, 		null: false
    end

    add_fk :dscripts, :scripts
  end
end
