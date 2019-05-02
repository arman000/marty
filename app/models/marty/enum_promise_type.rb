class Marty::EnumPromiseType < Marty::Base
  extend Marty::PgEnum

  VALUES = Set['delorean', 'ruby']
end
