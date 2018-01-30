class Gemini::XyzEnum < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = Set['Vanilla', 'Chocolate', 'Strawberry']
end
