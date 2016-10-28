class Gemini::EnumEventOperation < Gemini::Base
  extend Marty::EnumEventOperation

  VALUES = set['PRICING', 'CRA', 'AVM']
end
