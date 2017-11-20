class Gemini::XyzEnum < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = ['Vanilla', 'Chocolate', 'Strawberry']
end
