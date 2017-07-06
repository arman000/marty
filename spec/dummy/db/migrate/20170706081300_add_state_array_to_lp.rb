class AddStateArrayToLp < ActiveRecord::Migration
  def change
    add_column :gemini_loan_programs, :state_array, :enum_states,
               array: true, null: true
  end
end
