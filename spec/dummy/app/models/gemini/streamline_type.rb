class Gemini::StreamlineType < ActiveRecord::Base
  extend Marty::Enum

  self.table_name = 'gemini_streamline_types'

  def self.seed
    ["IRRRL",
     "FHA Streamline",
     "DURP",
     "Refi Plus",
     "Relief Refi Open Access",
     "Relief Refi",
     "Not Streamlined",
    ].each { |n| Gemini::StreamlineType.create(name: n) }
  end
end
