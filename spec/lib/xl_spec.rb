require 'spec_helper'
require 'marty'
require 'delorean_lang'

CODE = <<EOS
M:
    cfmt = {
        "type": ":cellIs",
        "priority": 1,
        "operator": ":greaterThan",
        "dxfId" : {
            "fg_color": "FFF8696B",
            "type": ":dxf",
            "b": true,
            },
        "formula": "$B$1",
        }

    hdr_style = {
        "font_name": "Calibri",
        "color": "FFFFFF",
        "b": true,
        "sz": 14,
        "style": {
            "bg_color": "0D056F",
            "fg_color": "FFFFFF",
            "alignment": {
                    "horizontal": ":center",
                    }
            },
        }

    #handles cell style
    c_style = {"style": [{"bg_color": "C5D9F1"}]}

    hi_style = {
        "b": true,
        "bg_color": "0D056F",
        "fg_color": "FFFFFF",
        }

    threshold_rows = [
        ["row", ["Threshold", 5], {"style": [hi_style, {}]}],
        ]

    title_header = [
        ["row", ["Sec Inst Name","Market Change Sec Inst"], hdr_style],
        ]
    rdata = [
         ["title", 2, 4, 5, 6, 8 ],
         ["text", 12, 4, 15, 6, 18 ],
         ["text", 22, 4, 25, 6, 28 ],
         ["text", 32, 4, 35, 6, 38 ],
         ["text", 42, 4, 45, 6, 48 ],
         ["text", 52, 4, 55, 6, 58 ],
         ["text", 62, 4, 65, 6, 68 ],
         ["text", 72, 4, 75, 6, 78 ]
         ]

    height = rdata.length()
    width = rdata[0].length()

    rows = [ ["row", r, c_style] for r in rdata ]

    raw = title_header +
        [["merge",  [1, {"off": 0}, width - 1, {"off": 0}]]] +
        [["conditional_formatting",
            [1, {"off": 1}, width, {"off": height }], cfmt]] +
        rows

    ws = ["A Sheet",
           [
             ["pos", [0, 0], threshold_rows ],
             ["pos", C1, raw ],
             ["pos", C2, raw ],
           ]
         ]

    title = "Per-Secutiry Market Change Report"
    form = []

    result = [ws]
    format = "xlsx"
EOS

describe Marty::Xl do
  let(:engine) do
    Delorean::Engine.new "YYY"
  end

  def worksheet(ind, c)
    code = CODE.clone
    map = { 'C1' => c[0].to_s, 'C2' => c[1].to_s }
    map.each { |k, v| code.sub!(k, v)  }
    engine.parse(code)
    engine.evaluate("M", ["result"]).flatten(1)
  end

  before(:all) do
    @coords = [
      [[9, 5], [2, 5]],   # coords for non-overlaping datasets
      [[5, 8], [2, 5]],   # coords for overlaping datasets
    ]
  end

  it "should be able to create a spreadsheet that includes multiple datasets that don't overlap " do
    ws = worksheet(0, @coords[0])
    sp = Marty::Xl.spreadsheet(ws)
    file = Tempfile.new('file.xlsx')
    lambda { sp.serialize(file) }.should_not raise_error()

    sp.workbook.worksheets[0].rows[0].cells[0..1].map(&:value).should ==
      ["Threshold", 5]

    sp.workbook.worksheets[0].rows[1].cells[0..1].map(&:value).should ==
      ["", ""]

    sp.workbook.worksheets[0].rows[5].cells[0..15].map(&:value).should ==
      ["", "", "Sec Inst Name", "Market Change Sec Inst", "", "", "", "",
       "", "Sec Inst Name", "Market Change Sec Inst", "", "", "", ""]

    sp.workbook.worksheets[0].rows[6].cells[0..15].map(&:value).should ==
      ["", "", "title", 2, 4, 5, 6, 8, "", "title", 2, 4, 5, 6, 8]

    sp.workbook.worksheets[0].rows[7].cells[0..15].map(&:value).should ==
      ["", "", "text", 12, 4, 15, 6, 18, "", "text", 12, 4, 15, 6, 18]

    sp.workbook.worksheets[0].rows[8].cells[0..15].map(&:value).should ==
      ["", "", "text", 22, 4, 25, 6, 28, "", "text", 22, 4, 25, 6, 28]

    sp.workbook.worksheets[0].rows[9].cells[0..15].map(&:value).should ==
      ["", "", "text", 32, 4, 35, 6, 38, "", "text", 32, 4, 35, 6, 38]

    sp.workbook.worksheets[0].rows[10].cells[0..15].map(&:value).should ==
      ["", "", "text", 42, 4, 45, 6, 48, "", "text", 42, 4, 45, 6, 48]

    sp.workbook.worksheets[0].rows[11].cells[0..15].map(&:value).should ==
      ["", "", "text", 52, 4, 55, 6, 58, "", "text", 52, 4, 55, 6, 58]

    sp.workbook.worksheets[0].rows[12].cells[0..15].map(&:value).should ==
      ["", "", "text", 62, 4, 65, 6, 68, "", "text", 62, 4, 65, 6, 68]

    sp.workbook.worksheets[0].rows[13].cells[0..15].map(&:value).should ==
      ["", "", "text", 72, 4, 75, 6, 78, "", "text", 72, 4, 75, 6, 78]
  end

  it "should be able to create a spreadsheet that includes multiple datasets that overlap " do
    ws = worksheet(1, @coords[1])
    sp = Marty::Xl.spreadsheet(ws)
    file = Tempfile.new('file.xlsx')
    lambda { sp.serialize(file) }.should_not raise_error()

    sp.workbook.worksheets[0].rows[0].cells[0..1].map(&:value).should ==
      ["Threshold", 5]

    sp.workbook.worksheets[0].rows[1].cells[0..1].map(&:value).should ==
      ["", ""]

    sp.workbook.worksheets[0].rows[5].cells[0..11].map(&:value).should ==
      ["", "", "Sec Inst Name", "Market Change Sec Inst", "", "", "", "", "", "", ""]

    sp.workbook.worksheets[0].rows[6].cells[0..11].map(&:value).should ==
      ["", "", "title", 2, 4, 5, 6, 8, "", "", ""]

    sp.workbook.worksheets[0].rows[7].cells[0..11].map(&:value).should ==
      ["", "", "text", 12, 4, 15, 6, 18, "", "", ""]

    sp.workbook.worksheets[0].rows[8].cells[0..11].map(&:value).should ==
      ["", "", "text", 22, 4, "Sec Inst Name", "Market Change Sec Inst", 28, "", "", ""]

    sp.workbook.worksheets[0].rows[9].cells[0..11].map(&:value).should ==
      ["", "", "text", 32, 4, "title", 2, 4, 5, 6, 8]

    sp.workbook.worksheets[0].rows[10].cells[0..11].map(&:value).should ==
      ["", "", "text", 42, 4, "text", 12, 4, 15, 6, 18]

    sp.workbook.worksheets[0].rows[11].cells[0..11].map(&:value).should ==
      ["", "", "text", 52, 4, "text", 22, 4, 25, 6, 28]

    sp.workbook.worksheets[0].rows[12].cells[0..11].map(&:value).should ==
      ["", "", "text", 62, 4, "text", 32, 4, 35, 6, 38]

    sp.workbook.worksheets[0].rows[13].cells[0..11].map(&:value).should ==
      ["", "", "text", 72, 4, "text", 42, 4, 45, 6, 48]

    sp.workbook.worksheets[0].rows[14].cells[0..11].map(&:value).should ==
      ["", "", "", "", "", "text", 52, 4, 55, 6, 58]

    sp.workbook.worksheets[0].rows[15].cells[0..11].map(&:value).should ==
      ["", "", "", "", "", "text", 62, 4, 65, 6, 68]

    sp.workbook.worksheets[0].rows[16].cells[0..11].map(&:value).should ==
      ["", "", "", "", "", "text", 72, 4, 75, 6, 78]
  end

  it "should not raise an exception when given an empty, frozen arg" do
    data = [].freeze
    expect { Marty::Xl.spreadsheet(data).to_stream.read }.to_not raise_error
  end
end
