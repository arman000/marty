class Marty::Role < Marty::Base
  extend Marty::Enum

  validates_uniqueness_of :name
  # FIXME: should have before_destroy
end
