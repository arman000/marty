class Gemini::RuleSubType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['SimpleRule','ComplexRule']
end
