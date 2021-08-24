module Marty
bud_cats = <<EOF
name
Conv Fixed 30
Conv Fixed 20
EOF

bud_cats2 = <<EOF
namex
Conv Fixed 20
EOF

fannie_bup1 = <<EOF
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
    ['entity', 'bud_category', 'note_rate', 'settlement_mm',
     'settlement_yy', 'buy_up', 'buy_down'],
    [nil, 'Conv Fixed 30', 2.250, 12, 2012, 4.42, 7.24],
    [nil, 'Conv Fixed 30', 2.375, 12, 2012, 4.42, 7.24],
    [nil, 'Conv Fixed 30', 2.500, 12, 2012, 4.413, 7.228],
    [nil, 'Conv Fixed 30', 2.625, 12, 2012, 4.375, 7.162],
    [nil, 'Conv Fixed 30', 2.750, 12, 2012, 4.329, 7.093],
    [nil, 'Conv Fixed 20', 2.875, 12, 2012, 4.248, 6.959],
  ]

fannie_bup2 = <<EOF
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

fannie_bup3 = <<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	2.250	1.123	2.345	12	2012
EOF

loan_programs = <<EOF
name	amortization_type	mortgage_type	streamline_type	high_balance_indicator	state_array	test_int_array	test_string_array
Conv Fixed 30 Year	Fixed	Conventional	Not Streamlined	false		[1]	"[""foo""]"
Conv Fixed 30 Year HB	Fixed	Conventional	Not Streamlined	true	"[""TN""]"	[1,2]	"[""foo"",""bar""]"
Conv Fixed 30 Year DURP <=80	Fixed	Conventional	DURP	false	"[""TN"",""CT""]"	[1,2,3]	"[""foo"",""bar""]"
Conv Fixed 30 Year DURP <=80 HB	Fixed	Conventional	DURP	true	"[""CA"",""NY""]"		"[""foo"",""hi mom""]"
EOF

loan_programs_comma = <<EOF
name,amortization_type,mortgage_type,state_array,test_string_array,streamline_type,high_balance_indicator
FHA Fixed 15 Year,Fixed,FHA,"[""FL"",""NV"",""ME""]","[""ABC"",""DEF""]",Not Streamlined,false
FHA Fixed 100 Year,Fixed,FHA,"[""FL"",""NV"",""ME""]","[""XYZ,"",""hi mom""]",Not Streamlined,false
EOF

loan_programs_encoded = <<EOF
name,amortization_type,mortgage_type,conforming,ltv_ratio_percent_range,high_balance_indicator,loan_amortization_period_count,streamline_type,extra_feature_type_id,arm_initial_reset_period_count,arm_initial_cap_percent,arm_periodic_cap_percent,arm_lifetime_cap_percent,arm_index_type_id,arm_margin_rate_percent,enum_state,state_array,test_int_array,test_string_array
VA Fixed 30 Year,Fixed,VA,true,,false,360,Not Streamlined,,,,,,,,,,eJyLNowFAAHTAOo=,eJyLVkrLz1eKBQAI+AJB
VA Fixed 30 Year HB,Fixed,VA,true,,true,360,Not Streamlined,,,,,,,,,eJyLVgrxU4oFAAWtAZ8=,eJyLNtQxigUAA9UBSA==,eJyLVkrLz1fSUUpKLFKKBQAbWAPm
VA Fixed 30 Year DURP <=80,Fixed,VA,true,,false,360,DURP,,,,,,,,,eJyLVgrxU9JRcg5RigUAD/UCpg==,eJyLNtQx0jGOBQAGlQGn,eJyLVkrLz1fSUUpKLFKKBQAbWAPm
VA Fixed 30 Year DURP <=80 HB,Fixed,VA,true,,true,360,DURP,,,,,,,,,eJyLVnJ2VNJR8otUigUADy8CmA==,,eJyLVkrLz1fSUcrIVMjNz1WKBQApLQTr
EOF

fannie_bup4 = <<EOF
loan_program	bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30 Year	Conv Fixed 30	2.250	1.123	2.345	12	2012
EOF

fannie_bup5 = <<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 20	2.250	1.123	2.345	12	2012
Conv Fixed XX	2.250	1.123	2.345	12	2012
EOF

fannie_bup6 = <<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	2.250	4.42000	7.24000	12	2012
Conv Fixed 30	2.375	a123	7.24000	12	2012
EOF

fannie_bup7 = <<EOF
bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
Conv Fixed 30	$2.250	4.42%	7.24%	12	2012
Conv Fixed 30	$2.375	4.42%	7.24%	12	2012
Conv Fixed 30	$2.500	4.41300	7.22800	12	2012
Conv Fixed 30	$2.625	4.37500	7.16200	12	2012
Conv Fixed 30	$2.750	4.32900	7.09300	12	2012
Conv Fixed 20	$2.875	4.24800	6.95900	12	2012
EOF

expected_report_header_len = 18

describe DataImporter do
  # New .call tests

  let(:expected_export_headers) do
    ['entity',
     'bud_category',
     'note_rate',
     'settlement_mm',
     'settlement_yy',
     'buy_up',
     'buy_down',
     'loan_amortization_period_count_range',
     'int4range_col',
     'int8range_col',
     'tsrange_col',
     'tstzrange_col',
     'daterange_col']
  end

  it 'should be able to import into classes with id as uniqueness' do
    pending('Fix data importer to handle at least group_id as mcfly_uniqueness')

    res = Marty::DataImporter.
          call(Gemini::Simple,
               [{ 'some_name' => 'hello' }])
    expect(res).to eq({ create: 1 })
    res = Marty::DataImporter.call(
      Gemini::Simple,
      [{ 'group_id' => Gemini::Simple.first.group_id, 'some_name' => 'hello' }]
    )
    expect(res).to eq({ same: 1 })
    expect(x).to eq(y)
  end

  it 'should be able to import fannie buyups' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    expect(res).to eq({ create: 2 })
    expect(Gemini::BudCategory.count).to eq(2)

    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    expect(res).to eq({ same: 2 })
    expect(Gemini::BudCategory.count).to eq(2)

    res = Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)
    expect(res).to eq({ create: 6 })
    expect(Gemini::FannieBup.count).to eq(6)

    # spot-check the import
    bc = Gemini::BudCategory.find_by(name: 'Conv Fixed 30')
    fb = Gemini::FannieBup.where(bud_category_id: bc.id, note_rate: 2.50).first
    expect(fb.buy_up).to eq(4.41300)
    expect(fb.buy_down).to eq(7.22800)

    res = Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)
    expect(res).to eq({ same: 6 })
    expect(Gemini::FannieBup.count).to eq(6)

    # dups should raise an error
    dup = fannie_bup1.split("\n")[-1]
    expect(lambda {
      Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1 + dup)
    }).to raise_error(Marty::DataImporter::Error)
  end

  it 'should be able to use comma separated files' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub("\t", ','),
           dt: 'infinity',
           col_sep: ',',
          )
    expect(res).to eq({ create: 6 })
    expect(Gemini::FannieBup.count).to eq(6)
  end

  it 'should be all-or-nothing' do
    expect(lambda {
      Marty::DataImporter.
      call(Gemini::BudCategory,
           bud_cats + bud_cats.sub(/name\n/, ''))
    }).to raise_error(Marty::DataImporter::Error)
    expect(Gemini::BudCategory.count).to eq(0)
  end

  it 'should be able to perform updates mixed with inserts' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)

    res = Marty::DataImporter.call(Gemini::FannieBup, fannie_bup3)
    expect(res).to eq({ update: 1 })

    res = Marty::DataImporter.call(Gemini::FannieBup, fannie_bup2)
    expect(res).to eq({ same: 2, create: 2, update: 2, blank: 2 })
  end

  it 'should be able to import with cleaner' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
          )
    expect(res).to eq({ create: 6 })

    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
          )
    expect(res).to eq({ same: 6 })

    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup3,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
          )
    expect(res).to eq({ update: 1, clean: 5 })

    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup2,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
          )
    expect(res).to eq({ create: 6, blank: 2, clean: 1 })
  end

  it 'should be able to import with validation' do
    Marty::DataImporter.call(Gemini::BudCategory, bud_cats)

    # first load some old data
    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1,
           dt: 'infinity',
          )
    expect(res).to eq({ create: 6 })

    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.sub('2012', '2100'), # change 1st row
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )
    }).to raise_error(Marty::DataImporter::Error)

    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub('2012', '2100'),
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )

    expect(res).to eq({ create: 6 })

    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup3,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )
    }).to raise_error(Marty::DataImporter::Error)

    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup3.gsub('2012', '2100'),
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )
    expect(res).to eq({ update: 1, clean: 11 })
  end

  it 'should be able to import with preprocess' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup7,
           dt: 'infinity',
           cleaner_proc: -> { Gemini::FannieBup.import_cleaner },
           col_sep: "\t",
           preprocess_proc: ->(data) { Gemini::FannieBup.import_preprocess(data) },
          )
    expect(res).to eq({ create: 6 })
  end

  it 'should be able to import with validation - allow prior month' do
    Marty::DataImporter.call(Gemini::BudCategory, bud_cats)

    # first load some data without any validation
    res = Marty::DataImporter.
      call(Gemini::FannieBup, fannie_bup1, dt: 'infinity')
    expect(res).to eq({ create: 6 })

    now = DateTime.now
    cm, cy = now.month, now.year
    pm1, py1 = (now - 1.month).month, (now - 1.month).year
    pm2, py2 = (now - 2.months).month, (now - 2.months).year

    # Load data into current mm/yy
    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub("12\t2012", "#{cm}\t#{cy}"),
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )
    }).to_not raise_error

    # Load data into prior mm/yy - should fail since import_validation
    # only allows current or future months
    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation(ids) },
          )
    }).to raise_error(Marty::DataImporter::Error)

    # Load data into prior mm/yy - should not fail since
    # import_validation_allow_prior_month is specified
    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation_allow_prior_month(ids) },
          )
    }).to_not raise_error

    # Load data into mm/yy more than 1 month prior - should fail even
    # if import_validation_allow_prior_month is specified
    expect(lambda {
      Marty::DataImporter.
      call(Gemini::FannieBup,
           fannie_bup1.gsub("12\t2012", "#{pm2}\t#{py2}"),
           dt: 'infinity',
           validation_proc: ->(ids) { Gemini::FannieBup.import_validation_allow_prior_month(ids) },
          )
    }).to raise_error(Marty::DataImporter::Error)
  end

  it 'should properly handle validation errors' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      call(Gemini::LoanProgram, loan_programs)
    expect(res).to eq({ create: 4 })

    begin
      Marty::DataImporter.call(Gemini::FannieBup, fannie_bup4)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([0])
    else
      raise 'should have had an exception'
    end
  end

  it 'should load array types (incl encoded)' do
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs)
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs_comma,
                                  'infinity', nil, nil, ',')
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs_encoded,
                                  'infinity', nil, nil, ',')
    lpset = Gemini::LoanProgram.all.pluck(:name, :state_array,
                                          :test_int_array,
                                          :test_string_array).to_set
    expect(lpset).to eq([['Conv Fixed 30 Year', nil, [1], ['foo']],
                         ['Conv Fixed 30 Year HB', ['TN'], [1, 2],
                          ['foo', 'bar']],
                         ['Conv Fixed 30 Year DURP <=80', ['TN', 'CT'],
                          [1, 2, 3], ['foo', 'bar']],
                         ['Conv Fixed 30 Year DURP <=80 HB', ['CA', 'NY'],
                          nil, ['foo', 'hi mom']],
                         ['FHA Fixed 15 Year', ['FL', 'NV', 'ME'], nil,
                          ['ABC', 'DEF']],
                         ['FHA Fixed 100 Year', ['FL', 'NV', 'ME'], nil,
                          ['XYZ,', 'hi mom']],
                         ['VA Fixed 30 Year', nil, [1], ['foo']],
                         ['VA Fixed 30 Year HB', ['TN'], [1, 2],
                          ['foo', 'bar']],
                         ['VA Fixed 30 Year DURP <=80', ['TN', 'CT'],
                          [1, 2, 3], ['foo', 'bar']],
                         ['VA Fixed 30 Year DURP <=80 HB', ['CA', 'NY'],
                          nil, ['foo', 'hi mom']],].to_set)
  end

  it 'should properly handle cases where an association item is missing' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)

    begin
      Marty::DataImporter.call(Gemini::FannieBup, fannie_bup5)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([1])
      expect(e.message).to match(/Conv Fixed XX/)
    else
      raise 'should have had an exception'
    end
  end

  it 'should check for bad header' do
    expect(lambda {
      Marty::DataImporter.call(Gemini::BudCategory, bud_cats2)
    }).to raise_error(Marty::DataImporter::Error, /namex/)
  end

  it 'should handle bad data' do
    res = Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    begin
      res = Marty::DataImporter.
        call(Gemini::FannieBup, fannie_bup6)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([1])
      expect(e.message).to match(/bad float/)
    else
      raise 'should have had an exception'
    end
  end

  it 'should be able to export' do
    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)
    p = Marty::Posting.do_create('BASE', DateTime.tomorrow, '?')

    res = Marty::Script.evaluate(
      nil, 'DataReport', 'TableReport', 'result_raw',
      'pt_name'    => p.name,
      'class_name' => 'Gemini::FannieBup',
    )
    expect(res[0]).to eq(expected_export_headers)
    expect(res[1..-1].map { |e| e.first(7) }.sort).to eq(
      fannie_bup1_export[1..-1].sort)
  end

  # Old .do_import_summary test

  it 'should be able to import into classes with id as uniqueness' do
    pending('Fix data importer to handle at least group_id as mcfly_uniqueness')

    res = Marty::DataImporter.
          do_import_summary(Gemini::Simple,
                            [{ 'some_name' => 'hello' }])
    expect(res).to eq({ create: 1 })
    res = Marty::DataImporter.do_import_summary(
      Gemini::Simple,
      [{ 'group_id' => Gemini::Simple.first.group_id, 'some_name' => 'hello' }]
    )
    expect(res).to eq({ same: 1 })
  end

  it 'should be able to import fannie buyups' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    expect(res).to eq({ create: 2 })
    expect(Gemini::BudCategory.count).to eq(2)

    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    expect(res).to eq({ same: 2 })
    expect(Gemini::BudCategory.count).to eq(2)

    res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
    expect(res).to eq({ create: 6 })
    expect(Gemini::FannieBup.count).to eq(6)

    # spot-check the import
    bc = Gemini::BudCategory.find_by(name: 'Conv Fixed 30')
    fb = Gemini::FannieBup.where(bud_category_id: bc.id, note_rate: 2.50).first
    expect(fb.buy_up).to eq(4.41300)
    expect(fb.buy_down).to eq(7.22800)

    res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
    expect(res).to eq({ same: 6 })
    expect(Gemini::FannieBup.count).to eq(6)

    # dups should raise an error
    dup = fannie_bup1.split("\n")[-1]
    expect(lambda {
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1 + dup)
    }).to raise_error(Marty::DataImporter::Error)
  end

  it 'should be able to use comma separated files' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub("\t", ','),
                        'infinity',
                        nil,
                        nil,
                        ',',
                       )
    expect(res).to eq({ create: 6 })
    expect(Gemini::FannieBup.count).to eq(6)
  end

  it 'should be all-or-nothing' do
    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::BudCategory,
                        bud_cats + bud_cats.sub(/name\n/, ''))
    }).to raise_error(Marty::DataImporter::Error)
    expect(Gemini::BudCategory.count).to eq(0)
  end

  it 'should be able to perform updates mixed with inserts' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)

    res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup3)
    expect(res).to eq({ update: 1 })

    res = Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup2)
    expect(res).to eq({ same: 2, create: 2, update: 2, blank: 2 })
  end

  it 'should be able to import with cleaner' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1,
                        'infinity',
                        'import_cleaner',
                       )
    expect(res).to eq({ create: 6 })

    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1,
                        'infinity',
                        'import_cleaner',
                       )
    expect(res).to eq({ same: 6 })

    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup3,
                        'infinity',
                        'import_cleaner',
                       )
    expect(res).to eq({ update: 1, clean: 5 })

    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup2,
                        'infinity',
                        'import_cleaner',
                       )
    expect(res).to eq({ create: 6, blank: 2, clean: 1 })
  end

  it 'should be able to import with validation' do
    Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

    # first load some old data
    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1,
                        'infinity',
                       )
    expect(res).to eq({ create: 6 })

    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.sub('2012', '2100'), # change 1st row
                        'infinity',
                        nil,
                        'import_validation',
                       )
    }).to raise_error(Marty::DataImporter::Error)

    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub('2012', '2100'),
                        'infinity',
                        nil,
                        'import_validation',
                       )

    expect(res).to eq({ create: 6 })

    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup3,
                        'infinity',
                        'import_cleaner',
                        'import_validation',
                       )
    }).to raise_error(Marty::DataImporter::Error)

    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup3.gsub('2012', '2100'),
                        'infinity',
                        'import_cleaner',
                        'import_validation',
                       )
    expect(res).to eq({ update: 1, clean: 11 })
  end

  it 'should be able to import with preprocess' do
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
    expect(res).to eq({ create: 6 })
  end

  it 'should be able to import with validation - allow prior month' do
    Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

    # first load some data without any validation
    res = Marty::DataImporter.
      do_import_summary(Gemini::FannieBup, fannie_bup1, 'infinity')
    expect(res).to eq({ create: 6 })

    now = DateTime.now
    cm, cy = now.month, now.year
    pm1, py1 = (now - 1.month).month, (now - 1.month).year
    pm2, py2 = (now - 2.months).month, (now - 2.months).year

    # Load data into current mm/yy
    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub("12\t2012", "#{cm}\t#{cy}"),
                        'infinity',
                        nil,
                        'import_validation',
                       )
    }).to_not raise_error

    # Load data into prior mm/yy - should fail since import_validation
    # only allows current or future months
    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
                        'infinity',
                        nil,
                        'import_validation',
                       )
    }).to raise_error(Marty::DataImporter::Error)

    # Load data into prior mm/yy - should not fail since
    # import_validation_allow_prior_month is specified
    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub("12\t2012", "#{pm1}\t#{py1}"),
                        'infinity',
                        nil,
                        'import_validation_allow_prior_month',
                       )
    }).to_not raise_error

    # Load data into mm/yy more than 1 month prior - should fail even
    # if import_validation_allow_prior_month is specified
    expect(lambda {
      Marty::DataImporter.
      do_import_summary(Gemini::FannieBup,
                        fannie_bup1.gsub("12\t2012", "#{pm2}\t#{py2}"),
                        'infinity',
                        nil,
                        'import_validation_allow_prior_month',
                       )
    }).to raise_error(Marty::DataImporter::Error)
  end

  it 'should properly handle validation errors' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    res = Marty::DataImporter.
      do_import_summary(Gemini::LoanProgram, loan_programs)
    expect(res).to eq({ create: 4 })

    begin
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup4)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([0])
    else
      raise 'should have had an exception'
    end
  end

  it 'should load array types (incl encoded)' do
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs)
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs_comma,
                                  'infinity', nil, nil, ',')
    Marty::DataImporter.do_import(Gemini::LoanProgram, loan_programs_encoded,
                                  'infinity', nil, nil, ',')
    lpset = Gemini::LoanProgram.all.pluck(:name, :state_array,
                                          :test_int_array,
                                          :test_string_array).to_set
    expect(lpset).to eq([['Conv Fixed 30 Year', nil, [1], ['foo']],
                         ['Conv Fixed 30 Year HB', ['TN'], [1, 2],
                          ['foo', 'bar']],
                         ['Conv Fixed 30 Year DURP <=80', ['TN', 'CT'],
                          [1, 2, 3], ['foo', 'bar']],
                         ['Conv Fixed 30 Year DURP <=80 HB', ['CA', 'NY'],
                          nil, ['foo', 'hi mom']],
                         ['FHA Fixed 15 Year', ['FL', 'NV', 'ME'], nil,
                          ['ABC', 'DEF']],
                         ['FHA Fixed 100 Year', ['FL', 'NV', 'ME'], nil,
                          ['XYZ,', 'hi mom']],
                         ['VA Fixed 30 Year', nil, [1], ['foo']],
                         ['VA Fixed 30 Year HB', ['TN'], [1, 2],
                          ['foo', 'bar']],
                         ['VA Fixed 30 Year DURP <=80', ['TN', 'CT'],
                          [1, 2, 3], ['foo', 'bar']],
                         ['VA Fixed 30 Year DURP <=80 HB', ['CA', 'NY'],
                          nil, ['foo', 'hi mom']],].to_set)
  end

  it 'should properly handle cases where an association item is missing' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)

    begin
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup5)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([1])
      expect(e.message).to match(/Conv Fixed XX/)
    else
      raise 'should have had an exception'
    end
  end

  it 'should check for bad header' do
    expect(lambda {
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats2)
    }).to raise_error(Marty::DataImporter::Error, /namex/)
  end

  it 'should handle bad data' do
    res = Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    begin
      res = Marty::DataImporter.
        do_import_summary(Gemini::FannieBup, fannie_bup6)
    rescue Marty::DataImporter::Error => e
      expect(e.lines).to eq([1])
      expect(e.message).to match(/bad float/)
    else
      raise 'should have had an exception'
    end
  end

  it 'should be able to export' do
    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
    p = Marty::Posting.do_create('BASE', DateTime.tomorrow, '?')

    res = Marty::Script.evaluate(
      nil, 'DataReport', 'TableReport', 'result_raw',
      'pt_name'    => p.name,
      'class_name' => 'Gemini::FannieBup',
    )
    expect(res[0]).to eq(expected_export_headers)
    expect(res[1..-1].map { |e| e.first(7) }.sort).to eq(
      fannie_bup1_export[1..-1].sort)
  end
end

# New
describe 'Blame Report without yml translations - call' do
  before(:each) do
    I18n.backend.store_translations(:en,
                                    attributes: {
                                      note_rate: nil
                                    }
                                   )
    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    p = Marty::Posting.do_create('BASE', DateTime.yesterday, 'yesterday')
    Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)
    p2 = Marty::Posting.do_create('BASE', DateTime.now, 'now is the time')

    @res = Marty::Script.evaluate(
      nil, 'BlameReport', 'DataBlameReport', 'result',
      'class_list' => ['Gemini::BudCategory', 'Gemini::FannieBup'],
      'dt1' => p.created_dt,
      'dt2' => p2.created_dt.end_of_day,
    )
  end

  context 'when exporting' do
    it 'exports the column_name' do
      expect(@res[0][1][0][1].length).to eq(expected_report_header_len)
      expect(@res[0][1][0][1][7]).to eq('note_rate')
    end
  end
end

# Old
describe 'Blame Report without yml translations' do
  before(:each) do
    I18n.backend.store_translations(:en,
                                    attributes: {
                                      note_rate: nil
                                    }
                                   )
    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    p = Marty::Posting.do_create('BASE', DateTime.yesterday, 'yesterday')
    Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
    p2 = Marty::Posting.do_create('BASE', DateTime.now, 'now is the time')

    @res = Marty::Script.evaluate(
      nil, 'BlameReport', 'DataBlameReport', 'result',
      'class_list' => ['Gemini::BudCategory', 'Gemini::FannieBup'],
      'dt1' => p.created_dt,
      'dt2' => p2.created_dt.end_of_day,
    )
  end

  context 'when exporting' do
    it 'exports the column_name' do
      expect(@res[0][1][0][1].length).to eq(expected_report_header_len)
      expect(@res[0][1][0][1][7]).to eq('note_rate')
    end
  end
end

# New
describe 'Blame Report with yml translations' do
  before(:each) do
    I18n.backend.store_translations(:en, attributes: { note_rate: 'Note Rate' })

    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    p = Marty::Posting.do_create('BASE', DateTime.yesterday, 'yesterday')
    Marty::DataImporter.call(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.call(Gemini::FannieBup, fannie_bup1)
    p2 = Marty::Posting.do_create('BASE', DateTime.now, 'now is the time')

    @res = Marty::Script.evaluate(
      nil, 'BlameReport', 'DataBlameReport', 'result',
      'class_list' => ['Gemini::BudCategory', 'Gemini::FannieBup'],
      'dt1' => p.created_dt,
      'dt2' => p2.created_dt.end_of_day,
    )
  end

  context 'when exporting' do
    it 'exports the locale value for the column header' do
      expect(@res[0][1][0][1].length).to eq(expected_report_header_len)
      expect(@res[0][1][0][1][7]).to eq('Note Rate')
    end
  end
end

# Old
describe 'Blame Report with yml translations' do
  before(:each) do
    I18n.backend.store_translations(:en, attributes: { note_rate: 'Note Rate' })

    Marty::Script.load_scripts(nil, Time.zone.today)
    Marty::ScriptSet.clear_cache
    p = Marty::Posting.do_create('BASE', DateTime.yesterday, 'yesterday')
    Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
    Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup1)
    p2 = Marty::Posting.do_create('BASE', DateTime.now, 'now is the time')

    @res = Marty::Script.evaluate(
      nil, 'BlameReport', 'DataBlameReport', 'result',
      'class_list' => ['Gemini::BudCategory', 'Gemini::FannieBup'],
      'dt1' => p.created_dt,
      'dt2' => p2.created_dt.end_of_day,
    )
  end

  context 'when exporting' do
    it 'exports the locale value for the column header' do
      expect(@res[0][1][0][1].length).to eq(expected_report_header_len)
      expect(@res[0][1][0][1][7]).to eq('Note Rate')
    end
  end
end
end
