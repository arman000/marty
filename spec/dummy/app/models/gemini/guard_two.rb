class Gemini::GuardTwo < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = Set['G2V1', 'G2V2', 'G2V3']
end
