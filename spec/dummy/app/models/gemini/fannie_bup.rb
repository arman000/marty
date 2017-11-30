module Gemini
  class FannieBup < Marty::Base
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

    def self.import_preprocess(data)
      data.map {
        |rec|
        rec["note_rate"].gsub! /\$/, ''
        rec["buy_up"].gsub! /\%/, ''
        rec["buy_down"].gsub! /\%/, ''
        rec
      }
    end
  end
end
