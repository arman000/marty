require 'spec_helper'

describe 'Blame Report', slow: true do
  U = 'marty marty'
  BC = 'Conv Fixed 30'

  before do
    marty_whodunnit

    Marty::Script.load_scripts(nil, Time.zone.now)

    time1 = Time.zone.parse '2019-01-23 05:14:50 -0800'
    time2 = Time.zone.parse '2019-01-24 05:14:50 -0800'
    time3 = Time.zone.parse '2019-01-25 05:14:50 -0800'
    time4 = Time.zone.parse '2019-01-26 05:14:50 -0800'
    time5 = Time.zone.parse '2019-01-27 05:14:50 -0800'

    posting = Marty::Posting.do_create('BASE', time3 - 2.hours, 'base posting')
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

    fannie_bup2.destroy!
    fannie_bup2.reload
    o_dt = fannie_bup2.obsoleted_dt.to_s

    fannie_bup1.update!(buy_up: 1.125, created_dt: time2)
    fannie_bup1.update!(buy_up: 1.126, created_dt: time4)
    fannie_bup1.update!(buy_up: 1.127, created_dt: time5)

    @res0 = [
      [time2.to_s, U, '', '', nil, BC, 2.25, 12, 2012, 1.125, 2.345],
      [time4.to_s, U, '', '', nil, BC, 2.25, 12, 2012, 1.126, 2.345],
      [time5.to_s, U, '', '', nil, BC, 2.25, 12, 2012, 1.127, 2.345],
      [time4.to_s, U, o_dt, U, nil, 'Govt Fixed 30', 2.25, 22, 2014,
       2.123, 3.345]
    ].freeze
  end

  it 'should generate Data Blame report' do
    ws = Marty::Script.evaluate(
      nil, 'BlameReport', 'DataBlameReport', 'result',
      # "class_list" param, defaults to all
      'pt_name1' => @pt_name,
      'pt_name2' => 'NOW',
    )

    sp = Marty::Xl.spreadsheet(ws)
    file = Tempfile.new('file.xlsx')
    expect { sp.serialize(file) }.to_not raise_error

    expect(sp.workbook.worksheets.map(&:name)).
      to eq(['GeminiFannieBup'])

    expect(sp.workbook.worksheets.count).to eq 1
    expect(sp.workbook.worksheets[0].rows.count).to eq 5

    @res0.each_with_index do |rec, i|
      cells = sp.workbook.worksheets[0].rows[i + 1].cells.map(&:value)
      expect(Set.new(cells[1..-1])).to eq Set.new(rec)
    end
  end
end
