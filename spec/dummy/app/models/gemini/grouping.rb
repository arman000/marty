class Gemini::Grouping < ActiveRecord::Base
  self.table_name = 'groupings'

  mcfly append_only: true

  validates_presence_of :name
  mcfly_validates_uniqueness_of :name
end
