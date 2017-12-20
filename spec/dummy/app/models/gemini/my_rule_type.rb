class Gemini::MyRuleType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['SimpleRule','ComplexRule']
end
