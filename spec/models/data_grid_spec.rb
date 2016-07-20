require 'spec_helper'

module Marty::DataGridSpec
  describe DataGrid do

G1 =<<EOS
state\tstring\tv\t\t
ltv\tnumrange\tv\t\t
fico\tnumrange\th\t\t

\t\t>=600<700\t>=700<750\t>=750
CA\t<=80\t1.1\t2.2\t3.3
TX|HI\t>80<=105\t4.4\t5.5\t6.6
NM\t<=80\t1.2\t2.3\t3.4
MA\t>80<=105\t4.5\t5.6\t
\t<=80\t11\t22\t33
EOS

G2 =<<EOS
units\tinteger\tv\t\t
ltv\tnumrange\tv\t\t
cltv\tnumrange\th\t\t
fico\tnumrange\th\t\t

\t\t>=100<110\t>=110<120\t>=120
\t\t>=600<700\t>=700<750\t>=750
1|2\t<=80\t1.1\t2.2\t3.3
1|2\t>80<=105\t4.4\t5.5\t6.6
3|4\t<=80\t1.2\t2.3\t3.4
3|4\t>80<=105\t4.5\t5.6\t6.7
EOS

G3 = File.open(File.expand_path("../srp_data.csv", __FILE__)).read

G4 =<<EOS
lenient
hb_indicator\tboolean\tv
cltv\tnumrange\th

\t<=60\t>60<=70\t>70<=75\t>75<=80\t>80<=85\t>85<=90\t>90<=95\t>95<=97
true\t-0.750\t-0.750\t-0.750\t-1.500\t-1.500\t-1.500\t\t
EOS

G5 =<<EOS
ltv\tnumrange\tv\t\t

<=115\t-0.375
>115<=135\t-0.750
EOS

G6 =<<EOS
ltv\tnumrange\th

<=115\t>115<=135
-0.375\t-0.750
EOS

G7 =<<EOS
string
hb_indicator\tboolean\tv
cltv\tnumrange\th

\t<=60\t>60<=70\t>70<=75\t>75<=80\t>80<=85\t>85<=90\t>90<=95\t>95<=97
true\tThis\tis\ta\ttest\tof\tstring type\t\t
EOS

G8 =<<EOS
Marty::DataGrid
ltv\tnumrange\tv\t\t

<=115\tG1
>115<=135\tG2
>135<=140\tG3
EOS

G9 =<<EOS
state\tstring\tv
ltv\tnumrange\tv

CA|TX\t>80\t123
\t>80\t456
EOS

Ga =<<EOS
dg\tMarty::DataGrid\tv\t\t

G1|G2\t7
G3\t8
EOS

Gb =<<EOS
property_state\tGemini::State\tv\t\t

CA|TX\t70
GA\t80
MN\t90
EOS

Gc =<<EOS
Marty::DataGrid
property_state\tGemini::State\tv\t\t

CA|TX\tGb
EOS

Gd =<<EOS
hb_indicator\tboolean\tv

true\t456
false\t123
EOS

Ge =<<EOS
ltv\tnumrange\th

>110\t>120
1.1\t1.1
EOS

Gf = <<EOS
lenient string
b\tboolean\tv
i\tinteger\tv
i4\tint4range\tv
n\tnumrange\tv

true\t1\t<10\t<10.0\tY
\t2\t\t\tM
false\t\t>10\t\tN
EOS

Gg = <<EOS
lenient
i1\tinteger\tv
i2\tinteger\tv

\t1\t1
2\t1\t21
2\t\t20
EOS

Gh = <<EOS
lenient
property_state\tstring\tv
county_name\tstring\tv

NY\t\t10
\tR\t8
EOS

Gi =<<EOS
units\tinteger\tv\t\t
ltv\tfloat\tv\t\t
cltv\tfloat\th\t\t
fico\tnumrange\th\t\t

\t\t80.5\t90.5\t100.5
\t\t>=600<700\t>=700<750\t>=750
1|2\t80.5\t1.1\t2.2\t3.3
1|2\t90.5\t4.4\t5.5\t6.6
3|4\t100.5\t1.2\t2.3\t3.4
3|4\t105.5\t4.5\t5.6\t6.7
EOS

    before(:each) do
      #Mcfly.whodunnit = Marty::User.find_by_login('marty')
      marty_whodunnit
    end

    def lookup_grid_helper(pt, gridname, params, follow=false)
      dg=Marty::DataGrid.lookup(pt, gridname)
      res=dg.lookup_grid_distinct_entry(pt, params, nil, follow)
      [res["result"], res["name"]]
    end

    describe "imports" do
      it "should not allow imports with trailing blank columns" do
        expect {
          dg_from_import("G1", G1.gsub("\n", "\t\n"))
        }.to raise_error(RuntimeError)
      end

      it "should not allow imports with last blank row" do
        expect {
          dg_from_import("Gh", Gh+"\t\t\n")
        }.to raise_error(RuntimeError)
      end
    end

    describe "validations" do
      it "a basic data grid should load ok" do
        dg_from_import("G1", G1)
        dg_from_import("G2", G2)
        dg_from_import("G3", G3)
        dg_from_import("G8", G8)
        dg_from_import("Ga", Ga)

        expect(Marty::DataGrid.lookup('infinity', "G1").name).to eq "G1"
        expect(Marty::DataGrid.lookup('infinity', "G2").name).to eq "G2"
        expect(Marty::DataGrid.lookup('infinity', "G3").name).to eq "G3"
      end

      it "should not allow bad axis types" do
        expect {
          dg_from_import("Gi", Gi)
        }.to raise_error(/unknown metadata type float/)
        expect {
          dg_from_import("Gi", Gi.sub(/float/, 'abcdef'))
        }.to raise_error(/unknown metadata type abcdef/)
      end

      it "should not allow dup attr names" do
        g_bad = G1.sub(/fico/, "ltv")

        expect {
          dg_from_import("G2", g_bad)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "should not allow dup grid names" do
        dg_from_import("G1", G1)

        expect {
          dg_from_import("G1", G2)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "should not allow extra attr rows" do
        g_bad = "x\tnumrange\th\t\t\n" + G1

        expect {
          dg_from_import("G2", g_bad)
        }.to raise_error(RuntimeError)
      end

      it "should not allow dup row/col key combos" do
        g_bad = G1 + G1.split("\n").last + "\n"
        expect {
          dg_from_import("G2", g_bad)
        }.to raise_error(ActiveRecord::RecordInvalid)

        g_bad = G2 + G2.split("\n").last + "\n"
        expect {
          dg_from_import("G2", g_bad)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "Unknown keys for typed grids should raise error" do
        g_bad = G8.sub(/G3/, "XXXXX")

        expect {
          dg_from_import("G8", g_bad)
        }.to raise_error(RuntimeError)

        g_bad = G8.sub(/DataGrid/, "Division")

        expect {
          dg_from_import("G8", g_bad)
        }.to raise_error(RuntimeError)
      end

      it "Unknown keys for grid headers should raise error" do
        g_bad = Ga.sub(/G3/, "XXXXX")

        expect {
          dg_from_import("Ga", g_bad)
        }.to raise_error(RuntimeError)

        g_bad = Ga.sub(/DataGrid/, "Division")

        expect {
          dg_from_import("Ga", g_bad)
        }.to raise_error(RuntimeError)
      end
    end

    describe "lookups for infinity" do
      let(:pt) { 'infinity'}

      before(:each) do
        ["G1", "G2", "G3", "G4", "G5", "G6", "G7", "G8", "Ga", "Gb",
         "Gc", "Gd", "Ge", "Gf", "Gg", "Gh"].each { |g|
          dg_from_import(g, "Marty::DataGridSpec::#{g}".constantize)
        }
      end

      context "should handle NULL key values" do
        let(:dg) { Marty::DataGrid.lookup(pt, "Gf") }

        it 'true returns Y' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"b"=>true}, false)
          expect(res).to eq('Y')
        end

        it '13 returns N' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"i"=>13}, true)
          expect(res).to eq('N')
        end

        it '13 & numrange 0 returns nil' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"i"=>13, "n"=>0}, true)
          expect(res).to eq('N')
        end

        it '13 & int4range 15 returns N' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"i"=>13, "i4"=>15}, true)
          expect(res).to eq('N')
        end

        it '13 & int4range 1 returns nil' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"i"=>13, "i4"=>1}, true)
          expect(res).to be_nil
        end

        it 'false, 3, numrange 15 returns N' do
          res = Marty::DataGrid.
                lookup_grid(pt, dg, {"b"=>false, "i"=>3, "n"=>15}, true)
          expect(res).to eq('N')
        end

        it '13, numrange 15 returns N' do
          res = Marty::DataGrid.lookup_grid(pt, dg, {"i"=>13, "n"=>15}, true)
          expect(res).to eq('N')
        end
      end

      it "should handle ambiguous lookups" do
        dg = Marty::DataGrid.lookup(pt, "Gh")

        h1 = {
          "property_state" => "NY",
          "county_name"    => "R",
        }

        res = Marty::DataGrid.lookup_grid(pt, dg, h1, false)
        expect(res).to eq(10)
      end

      it "should handle ambiguous lookups (2)" do
        dg = Marty::DataGrid.lookup(pt, "Gg")
        res = Marty::DataGrid.
              lookup_grid(pt, dg, {"i1"=>2, "i2"=>1}, false)
        expect(res).to eq(1)

        res = Marty::DataGrid.
              lookup_grid(pt, dg, {"i1"=>3, "i2"=>1}, false)
        expect(res).to eq(1)

        res = Marty::DataGrid.
              lookup_grid(pt, dg, {"i1"=>2, "i2"=>3}, false)
        expect(res).to eq(20)
      end

      it "should handle non-distinct lookups" do
        dg = Marty::DataGrid.lookup(pt, "Ge")
        res = Marty::DataGrid.lookup_grid(pt, dg, {"ltv"=>500}, false)

        expect(res).to eq(1.1)

        expect {
          Marty::DataGrid.lookup_grid(pt, dg, {"ltv"=>500}, true)
        }.to raise_error(RuntimeError)
      end

      it "should handle boolean lookups" do
        res = [true, false].map { |hb_indicator|
          lookup_grid_helper('infinity',
                             "Gd",
                             {"hb_indicator" => hb_indicator,
                             },
                            )
        }
        expect(res).to eq [[456.0, "Gd"], [123.0, "Gd"]]
      end

      it "should handle basic lookups" do
        res = lookup_grid_helper('infinity',
                                 "G3",
                                 {"amount" => 160300,
                                  "state" => "HI",
                                 },
                                )
        expect(res).to eq [1.655,"G3"]

        [3,4].each {
          |units|
          res = lookup_grid_helper('infinity',
                                   "G2",
                                   {"fico" => 720,
                                    "units" => units,
                                    "ltv" => 100,
                                    "cltv" => 110.1,
                                   },
                                  )
          expect(res).to eq [5.6,"G2"]
        }

        dg = Marty::DataGrid.lookup('infinity', "G1")

        h = {
          "fico" => 600,
          "state" => "RI",
          "ltv" => 10,
        }

        res = lookup_grid_helper('infinity', "G1", h)
        expect(res).to eq [11,"G1"]

        dg.update_from_import("G1", G1.sub(/11/, "111"))

        res = lookup_grid_helper('infinity', "G1", h)
        expect(res).to eq [111,"G1"]
      end

      it "should result in error when there are multiple cell hits" do
        expect {
          lookup_grid_helper('infinity',
                             "G2",
                             {"fico" => 720,
                              "ltv" => 100,
                              "cltv" => 110.1,
                             },
                            )
        }.to raise_error(RuntimeError)
      end

      it "should return nil when matching data grid cell is nil" do
        res = lookup_grid_helper('infinity',
                                 "G1",
                                 {"fico" => 800,
                                  "state" => "MA",
                                  "ltv" => 81,
                                 },
                                )
        expect(res).to eq [nil,"G1"]
      end

      it "should handle string wildcards" do
        res = lookup_grid_helper('infinity',
                                 "G1",
                                 {"fico" => 720,
                                  "state" => "GU",
                                  "ltv" => 80,
                                 },
                                )
        expect(res).to eq [22,"G1"]
      end

      it "should handle matches which also have a wildcard match" do
        dg_from_import("G9", G9)

        expect {
          res = lookup_grid_helper('infinity',
                                   "G9",
                                   {"state" => "CA", "ltv" => 81},
                                  )
        }.to raise_error(RuntimeError)

        res = lookup_grid_helper('infinity',
                                 "G9",
                                 {"state" => "GU", "ltv" => 81},
                                )
        expect(res).to eq [456,"G9"]
      end

      it "should handle nil attr values to match wildcard" do
        dg_from_import("G9", G9)

        res = lookup_grid_helper('infinity',
                               "G9",
                               {"state" => nil, "ltv" => 81},
                               )
        expect(res).to eq [456,"G9"]

        expect {
          res = lookup_grid_helper('infinity',
                                     "G9",
                                     {"state" => "CA", "ltv" => nil},
                                    )
        }.to raise_error(RuntimeError)
      end

      it "should handle boolean keys" do
        res = lookup_grid_helper('infinity',
                                 "G4",
                                 {"hb_indicator" => true,
                                  "cltv" => 80,
                                 },
                                )
        expect(res).to eq [-1.5,"G4"]

        res = lookup_grid_helper('infinity',
                                 "G4",
                                 {"hb_indicator" => false,
                                  "cltv" => 80,
                                 },
                                )
        expect(res).to eq [nil,"G4"]
      end

      it "should handle vertical-only grids" do
        res = lookup_grid_helper('infinity',
                                 "G5",
                                 {"ltv" => 80},
                                )
        expect(res).to eq [-0.375,"G5"]
      end

      it "should handle horiz-only grids" do
        res = lookup_grid_helper('infinity',
                                 "G6",
                                 {"ltv" => 80, "conforming" => true},
                                )
        expect(res).to eq [-0.375,"G6"]
      end

      it "should handle string typed data grids" do
        expect(Marty::DataGrid.lookup('infinity', "G7").data_type).to eq "string"

        res = lookup_grid_helper('infinity',
                                 "G7",
                                 {"hb_indicator" => true,
                                  "cltv" => 80,
                                 },
                                )
        expect(res).to eq ["test","G7"]
      end

      it "should handle DataGrid typed data grids" do
        expect(Marty::DataGrid.lookup('infinity', "G8").data_type).
          to eq "Marty::DataGrid"
        g1 = Marty::DataGrid.lookup('infinity', "G1")

        res = lookup_grid_helper('infinity',
                                 "G8",
                                 {"ltv" => 80,
                                 },
                                )
        expect(res).to eq [g1,"G8"]
      end

      it "should handle multi DataGrid lookups" do
        expect(Marty::DataGrid.lookup('infinity', "G8").data_type).
          to eq "Marty::DataGrid"
        g1 = Marty::DataGrid.lookup('infinity', "G1")

        h = {
          "fico" => 600,
          "state" => "RI",
          "ltv" => 10,
        }

        g1_res = lookup_grid_helper('infinity', "G1", h)
        expect(g1_res).to eq [11,"G1"]

        res = lookup_grid_helper('infinity',
                                       "G8",
                                       h,true
                                      )
        expect(g1_res).to eq res
      end

      it "should handle DataGrid typed data grids" do
        g1 = Marty::DataGrid.lookup('infinity', "G1")

        res = lookup_grid_helper('infinity',
                                 "Ga",
                                 {"dg" => g1,
                                 },
                                )
        expect(res).to eq [7,"Ga"]

        # should be able to lookup bu name as well
        res = lookup_grid_helper('infinity',
                                 "Ga",
                                 {"dg" => "G2",
                                 },
                                )
        expect(res).to eq [7,"Ga"]
      end

      it "should handle DataGrid typed data grids -- non mcfly" do
        ca = Gemini::State.find_by_name("CA")

        res = lookup_grid_helper('infinity',
                                 "Gb",
                                 {"property_state" => ca,
                                 },
                                )
        expect(res).to eq [70,"Gb"]

        # should be able to lookup bu name as well
        res = lookup_grid_helper('infinity',
                                 "Gb",
                                 {"property_state" => "CA",
                                 },
                                )
        expect(res).to eq [70,"Gb"]
      end

      it "should return grid data and metadata simple" do
        expected_data = [[1.1, 2.2, 3.3], [4.4, 5.5, 6.6], [1.2, 2.3, 3.4],
                         [4.5, 5.6, 6.7]]
        expected_metadata = [{"dir"=>"v",
                              "attr"=>"units",
                              "keys"=>[[1, 2], [1, 2], [3, 4], [3, 4]],
                              "type"=>"integer"},
                             {"dir"=>"v",
                              "attr"=>"ltv",
                              "keys"=>["[,80]", "(80,105]", "[,80]", "(80,105]"],
                              "type"=>"numrange"},
                             {"dir"=>"h",
                              "attr"=>"cltv",
                              "keys"=>["[100,110)", "[110,120)", "[120,]"],
                              "type"=>"numrange"},
                             {"dir"=>"h",
                              "attr"=>"fico",
                              "keys"=>["[600,700)", "[700,750)", "[750,]"],
                              "type"=>"numrange"}]

        dg = Marty::DataGrid.lookup(pt, 'G2')
        res = dg.lookup_grid_distinct_entry(pt, {}, nil, true, true)
        expect(res["data"]).to eq (expected_data)
        expect(res["metadata"]).to eq (expected_metadata)
      end

      it "should return grid data and metadata multi (following)" do
        expected_data =  [[1.1, 2.2, 3.3],[4.4, 5.5, 6.6],[1.2, 2.3, 3.4],
                          [4.5, 5.6, nil],[11.0, 22.0, 33.0]]
        expected_metadata = [{"dir"=>"v",
                              "attr"=>"state",
                              "keys"=>[["CA"], ["HI", "TX"], ["NM"], ["MA"], nil],
                              "type"=>"string"},
                             {"dir"=>"v",
                              "attr"=>"ltv",
                              "keys"=>["[,80]", "(80,105]", "[,80]", "(80,105]",
                                       "[,80]"],
                              "type"=>"numrange"},
                             {"dir"=>"h",
                              "attr"=>"fico",
                              "keys"=>["[600,700)", "[700,750)", "[750,]"],
                              "type"=>"numrange"}]
        dg = Marty::DataGrid.lookup(pt, 'G8')
        res = dg.lookup_grid_distinct_entry(pt, { "ltv" => 10,
                                                  "state" => "RI" }, nil, true,
                                            true)
        expect(res["data"]).to eq (expected_data)
        expect(res["metadata"]).to eq (expected_metadata)
      end

      it "should return grid data and metadata multi (not following)" do
        expected_data = [["G1"], ["G2"], ["G3"]]
        expected_metadata = [{"dir"=>"v",
                              "attr"=>"ltv",
                              "keys"=>["[,115]", "(115,135]", "(135,140]"],
                              "type"=>"numrange"}]
        dg = Marty::DataGrid.lookup(pt, 'G8')
        res = dg.lookup_grid_distinct_entry(pt, { "ltv" => 10,
                                                  "state" => "RI" }, nil, false,
                                            true)
        expect(res["data"]).to eq (expected_data)
        expect(res["metadata"]).to eq (expected_metadata)
      end
    end

    describe "updates" do
      it "should be possible to modify a grid referenced from a multi-grid" do
        dgb = dg_from_import("Gb", Gb, '1/1/2014')
        dgc = dg_from_import("Gc", Gc, '2/2/2014')

        dgb.update_from_import("Gb", Gb.sub(/70/, "333"), '1/1/2015')
        dgb.update_from_import("Gb", Gb.sub(/70/, "444"), '1/1/2016')

        res = dgc.lookup_grid_distinct_entry('2/2/2014',
                                             {"property_state" => "CA"})

        expect(res["result"]).to eq(70)

        res = dgc.lookup_grid_distinct_entry('2/2/2015',
                                             {"property_state" => "CA"})

        expect(res["result"]).to eq(333)

        res = dgc.lookup_grid_distinct_entry('2/2/2016',
                                             {"property_state" => "CA"})

        expect(res["result"]).to eq(444)
      end

      it "should not create a new version if no change has been made" do
        dg = dg_from_import("G4", G1)
        dg.update_from_import("G4", G1)
        expect(Marty::DataGrid.unscoped.where(group_id: dg.group_id).count).to eq 1
      end

      it "should be able to export and import back grids" do
        [G1, G2, G3, G4, G5, G6, G7, G8, G9, Ga, Gb].each_with_index do
          |grid, i|
          dg = dg_from_import("G#{i}", grid)
          g1 = dg.export
          dg = dg_from_import("Gx#{i}", g1)
          g2 = dg.export
          expect(g1).to eq g2
        end
      end

      it "should be able to externally export/import grids" do
        load_scripts(nil, Date.today)

        dg = dg_from_import("G1", G1)

        p = posting("BASE", DateTime.tomorrow, '?')

        engine = Marty::ScriptSet.new.get_engine("DataReport")
        res = engine.evaluate("TableReport",
                              "result",
                              {
                                "pt_name"    => p.name,
                                "class_name" => "Marty::DataGrid",
                              },
                             )

        # FIXME: really hacky removing "" (data_grid) -- This is a bug
        # in TableReport/CSV generation.
        res.gsub!(/\"\"/, '')
        sum = do_import_summary(Marty::DataGrid,
                                res,
                                'infinity',
                                nil,
                                nil,
                                ",",
                               )

        expect(sum).to eq({same: 1})

        res11 = res.sub(/G1/, "G11")

        sum = do_import_summary(Marty::DataGrid,
                                res11,
                                'infinity',
                                nil,
                                nil,
                                ",",
                               )

        expect(sum).to eq({create: 1})

        g1 = Marty::DataGrid.lookup('infinity', "G1")
        g11 = Marty::DataGrid.lookup('infinity', "G11")

        expect(g1.export).to eq g11.export
      end
    end
  end
end
