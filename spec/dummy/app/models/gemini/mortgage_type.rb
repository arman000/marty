class Gemini::MortgageType < ActiveRecord::Base
  extend Marty::Enum

  self.table_name = 'gemini_mortgage_types'
end
