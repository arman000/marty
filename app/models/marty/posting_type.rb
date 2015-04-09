class Marty::PostingType < Marty::Base
  extend Marty::Enum

  validates_presence_of :name
  validates_uniqueness_of :name

  # NOTE: lookup fn for backward compat -- to index enums, use []
  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end
end
