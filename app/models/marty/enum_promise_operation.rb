class Marty::EnumPromiseOperation < Marty::Base
  extend Marty::PgEnum

  VALUES = Set['UNKNOWN']
end
