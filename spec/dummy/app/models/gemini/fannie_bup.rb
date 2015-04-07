module Gemini
  class FannieBup < ActiveRecord::Base
    extend Gemini::Extras::DataImport
    extend Gemini::Extras::SettlementImport

    self.table_name = 'gemini_fannie_bups'

    has_mcfly
    mcfly_validates_uniqueness_of :note_rate,
    scope: [:entity_id,
            :bud_category_id,
            :settlement_mm,
            :settlement_yy,
           ]

    belongs_to :entity
    mcfly_belongs_to :bud_category
  end
end
