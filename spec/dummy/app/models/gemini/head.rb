class Gemini::Head < ActiveRecord::Base
  self.table_name = 'heads'

  mcfly

  mcfly_validates_uniqueness_of :name
end
