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

    gen_mcfly_lookup :lookup, {
                       entity: true,
                       note_rate: false
                     }
    gen_mcfly_lookup :lookup_p, {
                       entity: true,
                       note_rate: false
                     }, private: true
    gen_mcfly_lookup :clookup, {
                       entity: true,
                       note_rate: false
                     }, cache: true
    gen_mcfly_lookup :clookup_p, {
                       entity: true,
                       note_rate: false
                     }, cache: true, private: true
    gen_mcfly_lookup :lookupn, {
                       entity: true,
                       note_rate: false
                     }, mode: nil
    gen_mcfly_lookup :lookupn_p, {
                       entity: true,
                       note_rate: false
                     }, private: true, mode: nil
    gen_mcfly_lookup :clookupn, {
                       entity: true,
                       note_rate: false
                     }, cache: true, mode: nil
    gen_mcfly_lookup :clookupn_p, {
                       entity: true,
                       note_rate: false
                     }, cache: true, private: true, mode: nil

    mcfly_lookup :a_func, sig: 3 do
      |pt, e_id, bc_id|
      where(entity_id: e_id, bud_category_id: bc_id).
        order(:settlement_mm)
    end

    mcfly_lookup :b_func, sig: [3, 4] do
      |pt, e_id, bc_id, mm = nil|
      q = where(entity_id: e_id, bud_category_id: bc_id)
      q = q.where(settlement_mm: mm) if mm
      q.order(:settlement_mm).first
    end

    mcfly_lookup :a_func_p, sig: 3, private: true do
      |pt, e_id, bc_id|
      where(entity_id: e_id, bud_category_id: bc_id).
        order(:settlement_mm)
    end

    mcfly_lookup :b_func_p, sig: [3, 4], private: true do
      |pt, e_id, bc_id, mm = nil|
      q = where(entity_id: e_id, bud_category_id: bc_id)
      q = q.where(settlement_mm: mm) if mm
      q.order(:settlement_mm)
    end

    cached_mcfly_lookup :ca_func, sig: 3 do
      |pt, e_id, bc_id|
      where(entity_id: e_id, bud_category_id: bc_id).
        order(:settlement_mm)
    end


  end
end
