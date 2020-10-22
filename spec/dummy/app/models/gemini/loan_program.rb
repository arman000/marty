class Gemini::LoanProgram < ActiveRecord::Base

  self.table_name = 'gemini_loan_programs'

  mcfly
  mcfly_validates_uniqueness_of :name

  validates_presence_of :name, :amortization_type, :mortgage_type, :streamline_type

  belongs_to :amortization_type
  belongs_to :mortgage_type
  belongs_to :streamline_type
end
