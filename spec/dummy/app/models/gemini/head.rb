class Gemini::Head < ActiveRecord::Base
  self.table_name = 'heads'

  has_mcfly

  mcfly_validates_uniqueness_of :name
end
