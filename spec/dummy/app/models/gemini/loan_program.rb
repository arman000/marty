class Gemini::LoanProgram < ActiveRecord::Base

  self.table_name = 'gemini_loan_programs'

  has_mcfly
  mcfly_validates_uniqueness_of :name

  belongs_to :amortization_type
  belongs_to :mortgage_type
  belongs_to :streamline_type
end
