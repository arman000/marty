class Marty::PostingType < Marty::Base
  extend Marty::Enum

  validates :name, presence: true
  validates :name, uniqueness: true
end
