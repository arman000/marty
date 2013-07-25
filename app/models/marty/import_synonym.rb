class Marty::ImportSynonym < Marty::Base
  attr_accessible :import_type_id, :synonym, :internal_name

  validates_presence_of :import_type_id, :synonym
  validates_uniqueness_of :import_type_id, scope: [:synonym]

  belongs_to :import_type
end
