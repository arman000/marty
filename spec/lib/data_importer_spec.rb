require "spec_helper"

module Marty

bud_cats =<<EOF
name
Conv Fixed 30
Conv Fixed 20
EOF

bud_cats2 =<<EOF
namex
Conv Fixed 20
EOF

fannie_bup1 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	2.250	4.42000	7.24000	12	2012
Conv Fixed 30	2.375	4.42000	7.24000	12	2012
Conv Fixed 30	2.500	4.41300	7.22800	12	2012
Conv Fixed 30	2.625	4.37500	7.16200	12	2012
Conv Fixed 30	2.750	4.32900	7.09300	12	2012
Conv Fixed 20	2.875	4.24800	6.95900	12	2012
EOF

fannie_bup1_export =
    [
     ["entity", "bud_category", "note_rate", "settlement_mm",
      "settlement_yy", "buy_up", "buy_down"],
     [nil, "Conv Fixed 30", 2.250, 12, 2012, 4.42, 7.24],
     [nil, "Conv Fixed 30", 2.375, 12, 2012, 4.42, 7.24],
     [nil, "Conv Fixed 30", 2.500, 12, 2012, 4.413, 7.228],
     [nil, "Conv Fixed 30", 2.625, 12, 2012, 4.375, 7.162],
     [nil, "Conv Fixed 30", 2.750, 12, 2012, 4.329, 7.093],
     [nil, "Conv Fixed 20", 2.875, 12, 2012, 4.248, 6.959],
    ]

fannie_bup2 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 20	2.250	4.42000	7.24000	12	2012
Conv Fixed 20	2.375	4.42000	7.24000	12	2012
Conv Fixed 30	2.500	1.111	2.222	12	2012
Conv Fixed 30	2.625	4.37500	7.16200	12	2012
\t\t\t\t\t
Conv Fixed 30	2.750	4.32900	7.09300	12	2012
\t\t\t\t\t
Conv Fixed 20	2.875	3.333	4.444	12	2012
EOF

fannie_bup3 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	2.250	1.123	2.345	12	2012
EOF

loan_programs =<<EOF
name	amortization_type	mortgage_type	streamline_type	high_balance_indicator	state_array
Conv Fixed 30 Year	Fixed	Conventional	Not Streamlined	false	
Conv Fixed 30 Year HB	Fixed	Conventional	Not Streamlined	true	TN
Conv Fixed 30 Year DURP <=80	Fixed	Conventional	DURP	false	TN,CT
Conv Fixed 30 Year DURP <=80 HB	Fixed	Conventional	DURP	true	"CA,NY"
EOF

loan_programs_comma =<<EOF
name,amortization_type,mortgage_type,state_array,streamline_type,high_balance_indicator
FHA Fixed 15 Year,Fixed,FHA,"FL,NV,ME",Not Streamlined,false
EOF

fannie_bup4 =<<EOF
loan_program	bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30 Year	Conv Fixed 30	2.250	1.123	2.345	12	2012
EOF

fannie_bup5 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 20	2.250	1.123	2.345	12	2012
Conv Fixed XX	2.250	1.123	2.345	12	2012
EOF

fannie_bup6 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	2.250	4.42000	7.24000	12	2012
Conv Fixed 30	2.375	a123	7.24000	12	2012
EOF

fannie_bup7 =<<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	$2.250	4.42%	7.24%	12	2012
Conv Fixed 30	$2.375	4.42%	7.24%	12	2012
Conv Fixed 30	$2.500	4.41300	7.22800	12	2012
Conv Fixed 30	$2.625	4.37500	7.16200	12	2012
Conv Fixed 30	$2.750	4.32900	7.09300	12	2012
Conv Fixed 20	$2.875	4.24800	6.95900	12	2012
EOF

  describe DataImporter do
    it "should be able to import into classes with id as uniqueness" do
      pending("Fix data importer to handle at least group_id as mcfly_uniqueness")

      res = Marty::DataImporter.
            do_import_summary(Gemini::Simple,
                              [{"some_name" => "hello"}])
      res.should == {create: 1}
      res = Marty::DataImporter.
            do_import_summary(Gemini::Simple,
                              [{"group_id" => Gemini::Simple.first.group_id, "some_name" => "hello"}])
      res.should == {same: 1}
    end

    it "should be able to import fannie buyups" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res.should == {create: 2}
      Gemini::BudCategory.count.should == 2

      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res.should == {same: 2}
      Gemini::BudCategory.count.should == 2

      res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
      res.should == {create: 6}
      Gemini::FannieBup.count.should == 6

      # spot-check the import
      bc = Gemini::BudCategory.find_by_name("Conv Fixed 30")
      fb = Gemini::FannieBup.where(bud_category_id: bc.id, note_rate: 2.50).first
      fb.buy_up.should == 4.41300
      fb.buy_down.should == 7.22800

      res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
      res.should == {same: 6}
      Gemini::FannieBup.count.should == 6

      # dups should raise an error
      dup = fannie_bup1.split("\n")[-1]
      lambda {
        Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1+dup)
      }.should raise_error(Marty::DataImporterError)
    end

    it "should be able to use comma separated files" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("\t", ","),
                          'infinity',
                          nil,
                          nil,
                          ",",
                          )
      res.should == {create: 6}
      Gemini::FannieBup.count.should == 6
    end

    it "should be all-or-nothing" do
      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::BudCategory,
                          bud_cats+bud_cats.sub(/name\n/, ""))
      }.should raise_error(Marty::DataImporterError)
      Gemini::BudCategory.count.should == 0
    end

    it "should be able to perform updates mixed with inserts" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)

      res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup3)
      res.should == {update: 1}

      res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup2)
      res.should == {same: 2, create: 2, update: 2, blank: 2}
    end

    it "should be able to import with cleaner" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1,
                          'infinity',
                          'import_cleaner',
                          )
      res.should == {create: 6}

      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1,
                          'infinity',
                          'import_cleaner',
                          )
      res.should == {same: 6}

      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup3,
                          'infinity',
                          'import_cleaner',
                          )
      res.should == {update: 1, clean: 5}

      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup2,
                          'infinity',
                          'import_cleaner',
                          )
      res.should == {create: 6, blank: 2, clean: 1}
    end

    it "should be able to import with validation" do
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

      # first load some old data
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1,
                          'infinity',
                          )
      res.should == {create: 6}

      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.sub("2012", "2100"), # change 1st row
                          'infinity',
                          nil,
                          'import_validation',
                          )
      }.should raise_error(Marty::DataImporterError)

      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("2012", "2100"),
                          'infinity',
                          nil,
                          'import_validation',
                          )

      res.should == {create: 6}

      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup3,
                          'infinity',
                          'import_cleaner',
                          'import_validation',
                          )
      }.should raise_error(Marty::DataImporterError)

      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup3.gsub("2012", "2100"),
                          'infinity',
                          'import_cleaner',
                          'import_validation',
                          )
      res.should == {update: 1, clean: 11}
    end

    it "should be able to import with preprocess" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup7,
                          'infinity',
                          'import_cleaner',
                          nil,
                          "\t",
                          false,
                          'import_preprocess',
                         )
      res.should == {create: 6}
    end

    it "should be able to import with validation - allow prior month" do
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

      # first load some data without any validation
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup, fannie_bup1, 'infinity')
      res.should == {create: 6}

      now = DateTime.now
      cm, cy = now.month, now.year
      pm1, py1 = (now - 1.month).month, (now - 1.month).year
      pm2, py2 = (now - 2.months).month, (now - 2.months).year

      # Load data into current mm/yy
      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("12\t2012", "#{cm}\t#{cy}"),
                          'infinity',
                          nil,
                          'import_validation',
                          )
      }.should_not raise_error

      # Load data into prior mm/yy - should fail since import_validation
      # only allows current or future months
      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
                          'infinity',
                          nil,
                          'import_validation',
                          )
      }.should raise_error(Marty::DataImporterError)

      # Load data into prior mm/yy - should not fail since
      # import_validation_allow_prior_month is specified
      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
                          'infinity',
                          nil,
                          'import_validation_allow_prior_month',
                          )
      }.should_not raise_error

      # Load data into mm/yy more than 1 month prior - should fail even
      # if import_validation_allow_prior_month is specified
      lambda {
        Marty::DataImporter.
        do_import_summary(Gemini::FannieBup,
                          fannie_bup1.gsub("12\t2012", "#{pm2}\t#{py2}"),
                          'infinity',
                          nil,
                          'import_validation_allow_prior_month',
                          )
      }.should raise_error(Marty::DataImporterError)
    end

    it "should properly handle validation errors" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      res = Marty::DataImporter.
        do_import_summary(Gemini::LoanProgram, loan_programs)
      res.should == {create: 4}

      begin
        Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup4)
      rescue Marty::DataImporterError => exc
        exc.lines.should == [0]
      else
        raise "should have had an exception"
      end
    end

    it "should load enum array types" do
      Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs)
      Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs_comma,
                                    'infinity', nil, nil, ',')
      lpset = Gemini::LoanProgram.all.pluck(:name, :state_array).to_set
      expect(lpset).to eq([["Conv Fixed 30 Year", nil],
                           ["Conv Fixed 30 Year HB", ["TN"]],
                           ["Conv Fixed 30 Year DURP <=80", ["TN", "CT"]],
                           ["Conv Fixed 30 Year DURP <=80 HB", ["CA","NY"]],
                           ["FHA Fixed 15 Year", ["FL","NV","ME"]]
                          ].to_set)

    end

    it "should properly handle cases where an association item is missing" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

      begin
        Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup5)
      rescue Marty::DataImporterError => exc
        exc.lines.should == [1]
        exc.message.should =~ /Conv Fixed XX/
      else
        raise "should have had an exception"
      end
    end

    it "should check for bad header" do
      lambda {
        Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats2)
      }.should raise_error(Marty::DataImporterError, /namex/)
    end

    it "should handle bad data" do
      res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      begin
        res = Marty::DataImporter.
          do_import_summary(Gemini::FannieBup, fannie_bup6)
      rescue Marty::DataImporterError => exc
        exc.lines.should == [1]
        exc.message.should =~ /bad float/
      else
        raise "should have had an exception"
      end
    end

    it "should be able to export" do
      Marty::Script.load_scripts(nil, Date.today)
      Marty::ScriptSet.clear_cache
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
      p = Marty::Posting.do_create("BASE", DateTime.tomorrow, '?')

      engine = Marty::ScriptSet.new.get_engine("DataReport")
      res = engine.evaluate("TableReport",
                            "result_raw",
                            {
                              "pt_name"    => p.name,
                              "class_name" => "Gemini::FannieBup",
                            },
                            )
      res[0].should == fannie_bup1_export[0]
      res[1..-1].sort.should == fannie_bup1_export[1..-1].sort
    end
  end

  describe "Blame Report without yml translations" do
    before(:each) do
      I18n.backend.store_translations(:en, {
        attributes: {
          note_rate: nil
        }
      })
      Marty::Script.load_scripts(nil, Date.today)
      Marty::ScriptSet.clear_cache
      p = Marty::Posting.do_create("BASE", DateTime.yesterday, 'yesterday')
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
      p2 = Marty::Posting.do_create("BASE", DateTime.now, 'now is the time')
      engine = Marty::ScriptSet.new.get_engine("BlameReport")
      @res = engine.evaluate("DataBlameReport",
                             "result",
                             {
                               "pt_name1"    => p.name,
                               "pt_name2"    => p2.name
                             },
                            )
    end

    context 'when exporting' do
      it "exports the column_name" do
        expect(@res[0][1][0][1].length).to eq(12)
        expect(@res[0][1][0][1][7]).to eq("note_rate")
      end
    end
  end

  describe "Blame Report with yml translations" do
    before(:each) do
      I18n.backend.store_translations(:en, {
        attributes: {
          note_rate: "Note Rate"
        }
      })
      Marty::Script.load_scripts(nil, Date.today)
      Marty::ScriptSet.clear_cache
      p = Marty::Posting.do_create("BASE", DateTime.yesterday, 'yesterday')
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
      p2 = Marty::Posting.do_create("BASE", DateTime.now, 'now is the time')
      engine = Marty::ScriptSet.new.get_engine("BlameReport")
      @res = engine.evaluate("DataBlameReport",
                             "result",
                             {
                               "pt_name1"    => p.name,
                               "pt_name2"    => p2.name
                             },
                            )
    end

    context 'when exporting' do
      it "exports the locale value for the column header" do

        expect(@res[0][1][0][1].length).to eq(12)
        expect(@res[0][1][0][1][7]).to eq("Note Rate")
      end
    end
  end
end
