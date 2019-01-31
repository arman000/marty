require 'spec_helper'

describe "Blame Report", slow: true do
  RES0 = [
     ["bud_category", "note_rate", "settlement_mm", "settlement_yy", "buy_up"],
     ["Govt Fixed 30", "2.25", "22", "2010", "12.123"],
     ["Conv Fixed 30", "2.25", "12", "2012", "1.127"]
  ].freeze

  RES1 = [
    ["entity", "bud_category", "note_rate", "settlement_mm", "settlement_yy",
     "buy_up", "buy_down"],
    [nil, "Govt Fixed 30", "2.25", "22", "2014", "2.123", "3.345"],
    [nil, "Govt Fixed 30", "2.25", "22", "2010", "12.123", "3.345"],
    [nil, "Conv Fixed 30", "2.25", "12", "2012", "1.126", "2.345"]
  ].freeze

  before do
    marty_whodunnit

    Marty::Script.load_scripts(nil, Time.zone.now)

    time1 = Time.zone.parse '2019-01-23 05:14:50 -0800'
    time2 = Time.zone.parse '2019-01-24 05:14:50 -0800'
    time3 = Time.zone.parse '2019-01-25 05:14:50 -0800'
    time4 = Time.zone.parse '2019-01-26 05:14:50 -0800'
    time5 = Time.zone.parse '2019-01-27 05:14:50 -0800'

    posting = Marty::Posting.do_create("BASE", time5 - 2.hours, 'base posting')
    @pt_name = Marty::Posting.find_by_name(posting.name).name

    bc = Gemini::BudCategory.create(name: 'Conv Fixed 30', created_dt: time1)
    bc2 = Gemini::BudCategory.create(name: 'Govt Fixed 30', created_dt: time1)

    fannie_bup1 = Gemini::FannieBup.create(bud_category: bc,
                             note_rate: 2.250,
                             buy_up: 1.123,
                             buy_down: 2.345,
                             settlement_mm: 12,
                             settlement_yy: 2012,
                             created_dt: time1
                                          )

    fannie_bup2 = Gemini::FannieBup.create(bud_category: bc2,
                             note_rate: 2.250,
                             buy_up: 2.123,
                             buy_down: 3.345,
                             settlement_mm: 22,
                             settlement_yy: 2014,
                             created_dt: time4
                                          )

    fannie_bup3 = Gemini::FannieBup.create(bud_category: bc2,
                             note_rate: 2.250,
                             buy_up: 12.123,
                             buy_down: 3.345,
                             settlement_mm: 22,
                             settlement_yy: 2010,
                             created_dt: time4
                                          )

    fannie_bup2.destroy!
    fannie_bup1.update!(buy_up: 1.125, created_dt: time2)
    fannie_bup1.update!(buy_up: 1.126, created_dt: time4)
    fannie_bup1.update!(buy_up: 1.127, created_dt: time5)
  end

  it "should generate Table report" do
    engine = Marty::ScriptSet.new.get_engine("TableReport")
    ws = engine.evaluate(
      "TableReport", "result", {
        "pt_name" => 'NOW',
        "class_name" => "Gemini::FannieBup",
        "exclude_attrs" => ["entity_id", "buy_down"],
        "sort_field" => "settlement_yy"
      })

    parsed_csv = CSV.parse(ws)
    expect(parsed_csv).to eq RES0

    ws = engine.evaluate(
      "TableReport", "result", {
        "pt_name" => @pt_name,
        "class_name" => "Gemini::FannieBup",
      })

    parsed_csv = CSV.parse(ws)
    expect(parsed_csv).to eq RES1
  end
end
