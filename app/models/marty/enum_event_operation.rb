class Marty::EnumEventOperation < Marty::Base
  extend Marty::PgEnum

  VALUES = Set['UNKNOWN']
end
