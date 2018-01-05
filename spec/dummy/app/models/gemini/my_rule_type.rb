class Gemini::MyRuleType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = Set['SimpleRule','ComplexRule']
end
