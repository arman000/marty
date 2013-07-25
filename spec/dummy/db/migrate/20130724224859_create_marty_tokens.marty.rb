# This migration comes from marty (originally 6)
class CreateMartyTokens < ActiveRecord::Migration
  def change
    create_table :marty_tokens do |t|
      t.references :user, null: false
      t.string :value, default: "", null: false
      t.datetime :created_on, null: false
    end

    add_foreign_key(:marty_tokens, :marty_users, column: :user_id)
    add_index(:marty_tokens, [:user_id])
  end
end
