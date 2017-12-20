class Gemini::XyzRuleType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['XRule','YRule', 'ZRule']
end
