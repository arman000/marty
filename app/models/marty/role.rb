class Marty::Role < Marty::Base
  extend Marty::Enum

  # attr_accessible :name
  validates_uniqueness_of :name
  # FIXME: should have before_destroy
end
