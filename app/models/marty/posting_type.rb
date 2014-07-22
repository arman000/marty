class Marty::PostingType < Marty::Base
  extend Marty::Enum

  # attr_accessible :name
  validates_presence_of :name
  validates_uniqueness_of :name

  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end
end
