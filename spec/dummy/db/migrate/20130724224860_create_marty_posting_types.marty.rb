# This migration comes from marty (originally 8)
class CreateMartyPostingTypes < ActiveRecord::Migration
  def change
    create_table :marty_posting_types do |t|
      t.string 	:name, null: false
    end
  end
end
