class CreateGeminiStates < ActiveRecord::Migration[4.2]
  def change
    create_table :gemini_states do |t|
      t.string :name, null: false
      t.string :full_name, null: false
    end
  end
end
