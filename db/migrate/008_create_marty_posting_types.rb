class CreateMartyPostingTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_posting_types do |t|
      t.string :name, null: false, limit: 255
    end
  end
end
