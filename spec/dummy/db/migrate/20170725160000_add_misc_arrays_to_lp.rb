class AddMiscArraysToLp < ActiveRecord::Migration
  def change
    add_column :gemini_loan_programs, :test_int_array, :integer,
               array: true, null: true
    add_column :gemini_loan_programs, :test_string_array, :string,
               array: true, null: true
  end
end
