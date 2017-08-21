class AddStateArrayToLp < ActiveRecord::Migration[4.2]
  def change
    add_column :gemini_loan_programs, :state_array, :enum_states,
               array: true, null: true
  end
end
