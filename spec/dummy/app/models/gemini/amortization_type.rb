class Gemini::AmortizationType < ActiveRecord::Base
  extend Marty::Enum

  self.table_name = 'gemini_amortization_types'
end
