class Gemini::XyzRuleType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = Set['XRule','YRule', 'ZRule']
end
