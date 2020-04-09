class Marty::PostingType < Marty::Base
  extend Marty::PgEnum

  VALUES = ['BASE']
end
