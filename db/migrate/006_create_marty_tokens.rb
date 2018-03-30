class CreateMartyTokens < ActiveRecord::Migration[4.2]
  include Marty::Migrations

  def change
    create_table :marty_tokens do |t|
      t.references :user,       null: false
      t.string     :value,      null: false, limit: 255, default: ""
      t.datetime   :created_on, null: false
    end

    add_fk :marty_tokens, :marty_users, column: :user_id
    add_index(:marty_tokens, [:user_id])
  end
end
