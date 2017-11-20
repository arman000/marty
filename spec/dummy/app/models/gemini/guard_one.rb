class Gemini::GuardOne < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['G1V1', 'G1V2', 'G1V3']
end
