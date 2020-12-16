class Gemini::HeadVersion < ActiveRecord::Base
  self.table_name = 'head_versions'

  mcfly

  validates_presence_of \
  :version,
  :head_id

  mcfly_validates_uniqueness_of :head_id,
  scope: [:version]

  mcfly_belongs_to :head
end
