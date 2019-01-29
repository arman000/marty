require 'spec_helper'
require 'marty'
require 'delorean_lang'

STYLE_CODE = <<EOS
S:
    data =
        [
         [1, 2],
         [3, 4],
        ]

    raw =   [ [ "border", [1,0,1,2], {
              "style" : ":thin",
              "color" : "000000"
              } ]
            ] +
            [ [ "border", [0,1,2,1], {
              "style" : ":thick",
              "color" : "FF0000"
              } ]
            ] +
            [
             ["row", r]
             for r in data
            ]

    ws    = ["BorderExample", [ ["pos", [1, 1], raw] ] ]

    title = "Border Example"
    form = []
    format = "xlsx"
    result = [ws]
EOS

describe Marty::Xl do
  let(:engine) do
    Delorean::Engine.new "YYY"
  end

  before(:each) do
    code = STYLE_CODE.clone
    engine.parse(code)
    @ws = engine.evaluate("S", ["result"]).flatten(1)
  end

  it "should be able to create a spreadsheet with overlapping border styles" do
    sp = Marty::Xl.spreadsheet(@ws)
    wb = sp.workbook

    file = Tempfile.new('file2.xlsx')
    lambda { sp.serialize(file) }.should_not raise_error()

    def border_details(b)
      edges = []
      b.prs.each do |pr|
        edges << [pr.name, pr.style, pr.color.rgb]
      end
      edges.sort_by { |k| k[0] }
    end

    sp.workbook.worksheets[0].rows[0].cells[0..1].map(&:value).should ==
      ["", ""]

    sp.workbook.worksheets[0].rows[1].cells[0..2].map(&:value).should ==
      ["", 1, 2]

    sp.workbook.worksheets[0].rows[2].cells[0..2].map(&:value).should ==
      ["", 3, 4]

    wb.worksheets[0].styles.borders.count.should >= 4

    wb.worksheets[0].styles.borders.each_index do |i|
      b = border_details(wb.worksheets[0].styles.borders[i])

      case i
      when 0
        b.should == []
      when 2
        b.should == [[:left, :thin, "FF000000"]]
      when 3
        b.should == [[:top, :thick, "FFFF0000"]]
      when 4
        b.should == [[:left, :thin, "FF000000"], [:top, :thick, "FFFF0000"]]
      else
        next
      end
    end

    wb.worksheets[0].styles.cellXfs.count.should >= 8

    wb.worksheets[0].styles.cellXfs.each_index do |i|
      c = wb.worksheets[0].styles.cellXfs[i]
      case i
      when 3
        c.borderId.should == 0
      when 4
        c.borderId.should == 0
      when 5
        c.borderId.should == 2
      when 6
        c.borderId.should == 0
      when 7
        c.borderId.should == 3
      when 8
        c.borderId.should == 4
      else
        next
      end
    end
  end
end
