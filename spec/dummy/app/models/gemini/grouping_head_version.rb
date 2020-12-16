class Gemini::GroupingHeadVersion < ActiveRecord::Base
  self.table_name = 'grouping_head_versions'

  has_mcfly

  validates_presence_of \
  :grouping_id,
  :head_version_id

  mcfly_validates_uniqueness_of :grouping_id, scope: [:head_version_id]

  mcfly_belongs_to :grouping, class_name: "Gemini::Grouping"
  mcfly_belongs_to :head_version, class_name: "Gemini::HeadVersion"
end
