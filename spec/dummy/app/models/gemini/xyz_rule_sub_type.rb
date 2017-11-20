class Gemini::XyzRuleSubType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['XRule','YRule', 'ZRule']
end
