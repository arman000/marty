class Gemini::Base < ActiveRecord::Base
  self.table_name_prefix = "gemini_"
  self.abstract_class = true
  extend Gemini::Extras::DataImport
end
