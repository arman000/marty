module Marty::RuleSpec
  describe 'Rule' do
    before(:all) do
      @save_file = "/tmp/save_#{Process.pid}.psql"
      save_clean_db(@save_file)
      marty_whodunnit
      Marty::Script.load_scripts
      @ruleopts_myrule = ['simple_result', 'computed_value', 'final_value',
                          'grid_sum', 'c1', 'sr2']
      @ruleopts_xyz = ['bvlength', 'bv']
    end

    after(:all) do
      restore_clean_db(@save_file)
    end

    before(:each) do
      dt = DateTime.parse('2017-1-1')
      p = File.expand_path('../../fixtures/csv/rule', __FILE__)
      [Marty::DataGrid, Gemini::XyzRule, Gemini::MyRule].each do |klass|
        f = '%s/%s.csv' % [p, klass.to_s.sub(/(Gemini|Marty)::/, '')]
        Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ',')
      end
      Marty::Tag.do_create('2017-01-01', 'tag')
    end

    context 'validation' do
      subject do
        guards = (@g_array   ? { 'g_array' => @g_array } : {}) +
                 (@g_single  ? { 'g_single' => @g_single }  : {}) +
                 (@g_string  ? { 'g_string' => @g_string }  : {}) +
                 (@g_bool.nil?     ? {} : { 'g_bool'     => @g_bool })     +
                 (@g_nullbool.nil? ? {} : { 'g_nullbool' => @g_nullbool }) +
                 (@g_range   ? { 'g_range' => @g_range } : {}) +
                 (@g_integer ? { 'g_integer' => @g_integer } : {})
        Gemini::MyRule.create!(name: 'testrule',
                               rule_type: @rule_type,
                               start_dt: @start_dt || '2013-1-1',
                               end_dt:   @end_dt,
                               simple_guards: guards,
                               simple_guards_options: @simple_guards_options || {},
                               computed_guards: @computed_guards || {},
                               results: @results || {}
                              )
      end

      it 'detects type errors' do
        @rule_type = 'SimpleRule'
        @g_integer = 'abc'
        expect { subject }.to raise_error(/Guards - Wrong type for 'g_integer'/)
      end

      it 'detects value errors 1' do
        @rule_type = 'SimpleRule'
        @g_array = ['G1V1', 'abcd']
        expect { subject }.to raise_error(/Guards - Bad value 'abcd' for 'g_array'/)
      end

      it 'detects value errors 2' do
        @rule_type = 'SimpleRule'
        @g_array = ['G1V1', 'xyz', 'abc']
        exp = /Guards - Bad values 'xyz', 'abc' for 'g_array'/
        expect { subject }.to raise_error(exp)
      end

      it 'detects arity errors 1' do
        @rule_type = 'SimpleRule'
        @g_single = ['G2V1', 'G2V2']
        exp = /Guards - Wrong arity for 'g_single' .expected single got multi./
        expect { subject }.to raise_error(exp)
      end

      it 'detects arity errors 2' do
        @rule_type = 'SimpleRule'
        @g_array = 'G1V1'
        exp = /Guards - Wrong arity for 'g_array' .expected multi got single./
        expect { subject }.to raise_error(exp)
      end

      it 'detects errors in computed guards' do
        @rule_type = 'SimpleRule'
        @computed_guards = { 'guard1' => 'zvjsdf12.z8*' }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'computed_guards' .attribute guard1.: Syntax error")
        expect { subject }.to raise_error(exp)
      end

      it 'detects errors in computed results' do
        @rule_type = 'SimpleRule'
        @results = {
          'grid1_grid' => '"DataGrid1"',
          'grid2_grid' => '"DataGrid2"',
          'does_compute' => '1+2',
          'does_not_compute' => 'zvjsdf12.z8*'
        }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'results' .attribute does_not_compute.: Syntax error")
        expect { subject }.to raise_error(exp)
      end

      it 'detects errors in computed results 2' do
        @rule_type = 'SimpleRule'

        @results = {
          'grid1_grid' => '"DataGrid1"',
          'grid2_grid' => '"DataGrid1"',
          'grid3_grid' => '"DataGrid3"',
          'does_compute' => '1+2',
          'does_not_compute' => 'zvjsdf12.z8*'
        }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'results' .attribute does_not_compute.: Syntax error")
        expect { subject }.to raise_error(exp)
      end

      it 'avoids delorean parse bug (redline 168745)' do
        @rule_type = 'SimpleRule'

        @results = {
          'grid1_grid' => '"DataGrid1"',
          'grid2_grid' => '"DataGrid1"',
          'grid3_grid' => '"DataGrid3"',
          'parse_bug' => "true\n&& false"
        }
        expect { subject }.to_not raise_error
      end

      it 'detects errors in computed results 3' do
        @rule_type = 'SimpleRule'
        @results = {
          'grid1_grid' => '"DataGrid1"',
          'grid2_grid' => '"DataGrid1"',
          'grid3_grid' => '"DataGrid3"',
          'does_compute' => '1+2',
          'does_compute2' => '"string".length',
          'does_not_compute' => 'zvjsdf12.z8*',
          'does_compute3' => '[does_compute].sum'
        }

        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'results' .attribute does_not_compute.: Syntax error")
        expect { subject }.to raise_error(exp)
      end

      it 'reports bad grid names' do
        @rule_type = 'SimpleRule'
        @results = {
          'grid1_grid' => '"xyz"',
          'grid2_grid' => '"DataGrid2"',
          'grid3_grid' => '"DataGrid3"',
        }

        exp = /Results - Bad grid name 'xyz' for 'grid1_grid'/
        expect { subject }.to raise_error(exp)
      end

      describe 'simple_guards_options' do
        before do
          @rule_type = 'SimpleRule'
        end

        let(:simple_guards_options) do
          {
            'g_array' => { 'not' => true },
            'g_string' => { 'not' => true },
            'g_range' => { 'not' => true },
            'g_integer' => { 'not' => true },
            'g_bool' => { 'not' => true }
          }
        end

        it 'detects wrong simple guards options value' do
          @simple_guards_options = simple_guards_options.merge(
            'g_array' => { 'not' => 'wrong_type' }
          )

          exp = Regexp.new(
            "Error in rule 'testrule' 'simple_guard_options' ->"\
            " 'g_array' -> 'not' field must be a boolean"
          )

          expect { subject }.to raise_error(exp)
        end

        it 'detects wrong simple guards options field' do
          @simple_guards_options = {
            'g_integer_wrong' => { 'not' => true }
          }

          exp = Regexp.new(
            "Error in rule 'testrule' 'simple_guard_options' -> "\
            "'g_integer_wrong' -> 'not'.Guard 'g_integer_wrong' doesn't exist."
          )

          expect { subject }.to raise_error(exp)
        end

        it 'detects wrong simple guards options field2' do
          @simple_guards_options = {
            'g_nullbool' => { 'not' => true }
          }

          exp = Regexp.new(
            "Error in rule 'testrule' 'simple_guard_options' ->"\
            " 'g_nullbool' -> 'not'. True value is not allowed"
          )
          expect { subject }.to raise_error(exp)
        end

        it 'saves' do
          @simple_guards_options = simple_guards_options
          expect { subject }.to_not raise_error
        end
      end

      it 'sets guard defaults correctly' do
        vals = Gemini::MyRule.all.map do |r|
          [r.name, r.simple_guards['g_has_default']]
        end
        expect(vals.sort).to eq(
          [
            ['NotRule1', 'foo'],
            ['NotRule2', 'foo'],
            ['NotRule3', 'foo'],
            ['Rule1', 'different'],
            ['Rule2', 'string default'],
            ['Rule2a', 'string default'],
            ['Rule2b', 'string default'],
            ['Rule2c', 'string default'],
            ['Rule3', 'string default'],
            ['Rule4', 'string default'],
            ['Rule5', 'foo']
          ].sort
        )
      end
    end
    context 'validation (xyz type)' do
      subject do
        r = Gemini::XyzRule.create!(
          name: 'testrule',
                                rule_type: @rule_type,
                                start_dt: @start_dt || '2013-1-1',
                                end_dt: @end_dt,
                                simple_guards: {},
                               computed_guards: @computed_guards || {},
                               grids: @grids || {},
                               results: @results || {}
        )
        r.reload
      end
      it 'detects script errors' do
        @rule_type = 'XRule'
        @results = { 'x' => 'zx sdf wer' }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'results' .attribute x.: Syntax error")
        expect { subject }.to raise_error(exp)
      end
      it 'rule script stuff overrides 1' do
        @rule_type = 'XRule'
        @computed_guards = { 'abc' => 'true', 'xyz_guard' => 'err err err' }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'xyz' .line 1.: Syntax error")
        expect { subject }.to raise_error(exp)
      end
      it 'rule script stuff overrides 2' do
        @rule_type = 'XRule'
        @computed_guards = { 'abc' => 'err err err', 'xyz_guard' => 'xyz_param' }
        exp = Regexp.new("Computed - Error in rule 'testrule' field "\
                         "'computed_guards' .attribute abc.: Syntax error")
        expect { subject }.to raise_error(exp)
      end
      it 'rule script stuff overrides 3' do
        @rule_type = 'XRule'
        @computed_guards = { 'abc' => 'true', 'xyz_guard' => '!xyz_param' }
        rule = subject
        expect(rule.compute_xyz('infinity', true)).to be false
        expect(rule.compute_xyz('infinity', false)).to be true
      end

      it 'no error' do
        @rule_type = 'XRule'
        @results = { 'x' => '1' }
        expect { subject }.not_to raise_error
      end
    end

    context 'lookups' do
      it 'matches' do
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_array' => 'G1V3')
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule1')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule',

                                            'other_flag' => true },
                                            {})
        expect(lookup.to_a.count).to eq(4)
        expect(lookup.map(&:name).to_set).to eq(Set['Rule2', 'Rule2a',
                                                    'Rule2b', 'Rule2c'])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'ComplexRule',
                                            'other_flag' => false },
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule3')
        # bool false matches bool nil
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'ComplexRule',
                                            'other_flag' => false },
                                            'g_bool' => false)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule3')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'ComplexRule' },
                                            'g_string' => 'def')
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule3')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'ComplexRule' },
                                            'g_string' => 'abc')
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_bool' => true, 'g_range' => 25,
                                            'g_integer' => 99)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule2a')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_bool' => true, 'g_range' => 75)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule1')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_bool' => true, 'g_range' => 75,
                                            'g_integer' => 11)
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_bool' => true, 'g_range' => 75,
                                            'g_integer' => 10)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule1')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' },
                                            'g_bool' => false, 'g_range' => 25,
                                            'g_integer' => 10)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq('Rule2c')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_type' => 'SimpleRule' }, {})
        expect(lookup.to_a.count).to eq(8)
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_dt' => '2017-3-1 02:00:00' },
                                            {})
        expect(lookup.to_a.count).to eq(6)
        expect(lookup.pluck(:name).to_set).to eq(Set['Rule1', 'Rule2', 'Rule2a',
                                                     'Rule2b', 'Rule2c', 'Rule3'])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_dt' => '2017-4-1 16:00:00' },
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.pluck(:name).first).to eq('Rule4')
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_dt' => '2016-12-31' }, {})
        expect(lookup.to_a).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            { 'rule_dt' => '2017-5-1 00:00:01' }, {})
        expect(lookup.to_a).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_bool_def' => false,
                                            'g_nbool_def' => true)
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.pluck(:name).first).to eq('Rule1')

        #####
        # NOT lookups
        #####
        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_bool_def' => true,
                                            'g_integer' => 3757)
        expect(lookup.to_a.count).to eq(2)
        expect(lookup.pluck(:name).sort).to eq(['NotRule1', 'Rule5'])

        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_bool_def' => true,
                                            'g_integer' => 100500)
        expect(lookup.to_a.count).to eq(2)
        expect(lookup.pluck(:name).sort).to eq(['NotRule2', 'NotRule3'])

        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_string' => 'wrong',
                                            'g_range' => 20
        )
        expect(lookup.to_a.count).to eq(2)
        expect(lookup.pluck(:name).sort).to eq(['NotRule1', 'NotRule2'])

        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_string' => 'wrong',
        )
        expect(lookup.to_a.count).to eq(3)
        expect(lookup.pluck(:name).sort).to eq(['NotRule1', 'NotRule2', 'NotRule3'])

        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            'g_range' => 250,
                                            'g_string' => 'wrong')
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.pluck(:name).sort).to eq(['NotRule3'])
      end
    end

    context 'rule compute' do
      let(:complex) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'ComplexRule' },
                                   'g_string' => 'def').first
      end
      let(:xyz) do
        Gemini::XyzRule.get_matches('infinity',
                                    { 'rule_type' => 'ZRule' },
                                    'g_integer' => 2).first
      end
      let(:simple) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'SimpleRule' },
                                   'g_bool' => true, 'g_range' => 25).first
      end
      let(:simple2a) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'SimpleRule' },
                                   'g_bool' => true, 'g_integer' => 99).first
      end
      let(:simple2b) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'SimpleRule' },
                                   'g_bool' => true, 'g_integer' => 999).first
      end
      let(:altgridmethod) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'ComplexRule' },
                                   'g_integer' => 3757).first
      end
      let(:gridcomputedname) do
        Gemini::MyRule.get_matches('infinity',
                                   { 'rule_type' => 'ComplexRule' },
                                   'g_string' => 'Hi Mom',
                                   'g_integer' => 11).first
      end

      it 'computed guards work' do
        c = complex.compute(@ruleopts_myrule,  'pt' => Time.zone.now,
                                               'param2' => 'def')
        expect(c).to eq('cguard2' => [false, 'a string'])
      end

      it 'returns simple results via #fixed_results' do
        expect(simple.fixed_results['simple_result']).to eq('b value')
        expect(simple.fixed_results['sr2']).to eq(true)
        expect(simple.fixed_results['sr3']).to eq(123)
        ssq = 'string with single quotes'
        expect(simple.fixed_results['single_quote']).to eq(ssq)
        swh = ' string that contains a # character'
        expect(simple.fixed_results['stringwithhash']).to eq(swh)
        expect(simple.fixed_results.count).to eq(5)

        # simple2b should evals grids
        expect(
          simple2b.compute(
            ['grid1_grid_result', 'grid2_grid_result'],
            'pt' => Time.zone.now,
            'param1' => 66,
            'param2' => 'abc',
            'paramb' => false
          )
        ).to eq('grid1_grid_result' => 3,
                 'grid2_grid_result' => 1300)

        allow_any_instance_of(Delorean::Engine).
          to receive(:evaluate).and_raise('hi mom')

        expect do
          simple.compute(@ruleopts_myrule,
                         'pt' => Time.zone.now)
        end        .to raise_error(/hi mom/)

        # simple2a should return results without evaluation (they are all fixed)
        expect(simple2a.compute(@ruleopts_myrule, 'pt' => Time.zone.now)).to eq(
          'simple_result' => 'b value',
          'sr2' => true,
        )
      end

      it 'returns computed results' do
        c = complex.compute(@ruleopts_myrule,  'pt' => Time.zone.now,
                                               'param1' => 66,
                                               'param2' => 'abc',
                                               'paramb' => false)

        expect(c).to eq('simple_result' => 'c value', 'computed_value' => 19)
      end

      it 'returns computed results 2' do
        c = complex.compute(
          @ruleopts_myrule + ['grid1_grid_result', 'grid2_grid_result'],
          'pt' => Time.zone.now,
          'param1' => 66,
          'param2' => 'abc',
          'paramb' => false,
        )

        expect(c).to eq('simple_result' => 'c value',
                        'computed_value' => 19,
                        'grid1_grid_result' => 3,
                        'grid2_grid_result' => 1300)
      end

      it 'returns computed results with deprecated grids' do
        complex.grids = { 'grid1' => 'DataGrid1', 'grid2' => 'DataGrid2' }
        complex.results.delete('grid1_grid')
        complex.results.delete('grid2_grid')
        complex.save!(validate: false)

        c = complex.compute(
          @ruleopts_myrule,
          'pt' => Time.zone.now,
          'param1' => 66,
          'param2' => 'abc',
          'paramb' => false,
        )

        expect(c).to eq('simple_result' => 'c value',
                        'computed_value' => 19,
                        'grid1_grid_result' => 3,
                        'grid2_grid_result' => 1300)
      end

      it 'returns computed results (with delorean import)' do
        c = xyz.compute(
          @ruleopts_xyz + ['grid1_grid_result'],
          'pt' => Time.zone.now + 1,
          'p1' => 12,
          'p2' => 3,
          'flavor' => 'cherry'
        )

        expect(c).to eq('bvlength' => 13, 'bv' => 'cherry --> 36',
                         'grid1_grid_result' => 19)
      end

      it 'passes only required arguments to data grids' do
        new_results = {
          'e1' => 'ERR("Should not be called")',
          'e2' => 'ERR("Should not be called")',
          'p2' => 'Gemini::MyRule.test_fn1() || 15',
          'e3' => 'ERR("Should not be called")',
          'p3' => 'ERR("Should not be called")',
          'flavor' => 'Gemini::MyRule.test_fn1() || "lemon"',
          'grid2_grid' => '"DataGrid2"',
          'grid1_grid' => '"DataGrid" + "3"',
          'simple_result' => '"c value"',
          'computed_value' => "if paramb\n"\
            "    then param1 / (grid1_grid_result||1)\n" \
            '     else (grid2_grid_result||1) / param1'
        }

        complex.update!(results: new_results)

        expect(Gemini::MyRule).to receive(:test_fn1).and_call_original.twice

        expect(Marty::DataGrid).to receive(:lookup_grid_h).and_wrap_original do |m, *args|
          dgn = args[1]
          h_passed = args[2]
          expect(dgn).to eq 'DataGrid3'
          expect(h_passed).to_not have_key('p3')
          expect(h_passed['p2']).to eq(15)
          expect(h_passed['flavor']).to eq('lemon')

          m.call(*args)
        end

        c = complex.compute(@ruleopts_myrule,  'pt' => Time.zone.now,
                                               'param1' => 66,
                                               'param2' => 'abc',
                                               'paramb' => true)

        expect(c).to eq('simple_result' => 'c value',
                        'computed_value' => 8)
      end

      it 'reports bad grid name' do
        exp = Regexp.new("Error .results. in rule '\\d+:Rule4': "\
                         'DataGridX grid not found')
        expect do
          gridcomputedname.compute(@ruleopts_myrule,
                                   'pt' => Time.zone.now,
                                   'param1' => 66,
                                   'param2' => 'abc',
                                   'paramb' => false)
        end.to raise_error(exp)
      end

      it 'grids embedded in result work properly and receive prior attrs' do
        v = altgridmethod.compute(
          @ruleopts_myrule,
          'pt' => Time.zone.now,
          'param1' => 45,
          'param2' => 1
        )

        expect(v['final_value']).to eq(15)
      end

      it 'exceptions/logging' do
        r6, r7, r8 = [6, 7, 8].map do |i|
          Gemini::XyzRule.get_matches('infinity',
                                      { 'rule_type' => 'ZRule' },
                                      'g_integer' => i).first
        end

        pt = Time.zone.now + 1
        input = { 'pt' => pt,
                 'p1' => 12,
                 'p2' => 3,
                 'flavor' => 'cherry' }
        v1 = r6.compute(@ruleopts_xyz, input)

        begin
          v2 = r7.compute(@ruleopts_xyz, input)
        rescue Marty::DeloreanRule::ComputeError => e
          exp = 'no implicit conversion of Integer into String'
          expect(e.message).to include(exp)
          expres = [/DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .+'/,
                    /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .tmp_var4__D'/,
                    /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .bv__D'/]

          expres.each_with_index do |expre, i|
            expect(e.backtrace[i]).to match(expre)
          end

          expect(e.input).to eq(input + { 'dgparams__' => input })
          expect(e.section).to eq('results')
        end

        begin
          v2 = r8.compute(@ruleopts_xyz, input)
        rescue Marty::DeloreanRule::ComputeError => e
          exp = 'divided by 0'
          expect(e.message).to include(exp)
          expres = [%r(DELOREAN__XyzRule_\d+_1483228800.0:\d+:in ./'),
                    /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .cg1__D'/]

          expres.each_with_index do |expre, i|
            expect(e.backtrace[i]).to match(expre)
          end

          expect(e.input).to eq(input)
          expect(e.section).to eq('computed_guards')
        end

        log_ents = Marty::Log.all
        expect(log_ents.map(&:message)).to eq(['Rule Log ZRule6',
                                               'Rule Log ZRule7',
                                               'Rule Log ZRule8'])
        ptjson = pt.as_json
        exp = {
          'input' => {
            'p1' => 12, 'p2' => 3,
            'pt' => ptjson,
            'flavor' => 'cherry'
          },
          'dgparams' => {
            'p1' => 12, 'p2' => 3,
             'pt' => ptjson,
             'flavor' => 'cherry'
          },
          'res_hash' => {
            'bv' => 'a stringa stringa stringa stringa stringa stringa stringa '\
            'stringa stringa stringa stringa stringa stringa stringa '\
            'stringa stringa stringa stringa stringa stringa stringa '\
            'stringa stringa stringa stringa string',
          }
        }

        expect(log_ents[0].details).to eq(exp)

        exp = {
          'input' => {
            'p1' => 12,
            'p2' => 3,
            'pt' => ptjson,
            'flavor' => 'cherry'
          },
          'cg_hash' => { 'some_guard' => true },
          'dgparams' => {
            'p1' => 12,
            'p2' => 3,
            'pt' => ptjson,
            'flavor' => 'cherry'
          },
         'res_keys' => ['bv'],
         'err_section' => 'results',
         'err_message' => 'no implicit conversion of Integer into String'
        }

        expect(log_ents[1].details.except('err_stack')).to eq(exp)

        expres = [/DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .+'/,
                  /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .tmp_var4__D'/,
                  /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .bv__D'/]

        expres.each_with_index do |expre, i|
          expect(log_ents[1].details['err_stack'][i]).to match(expre)
        end

        exp = { 'input' => { 'p1' => 12, 'p2' => 3,
                         'pt' => ptjson,
                         'flavor' => 'cherry' },
               'cg_keys' => ['cg1'],
               'dgparams' => { 'p1' => 12, 'p2' => 3,
                            'pt' => ptjson,
                            'flavor' => 'cherry' },
               'err_section' => 'computed_guards',
               'err_message' => 'divided by 0' }

        expect(log_ents[2].details.except('err_stack')).to eq(exp)
        expres = [%r(DELOREAN__XyzRule_\d+_1483228800.0:\d+:in ./'),
                  /DELOREAN__XyzRule_\d+_1483228800.0:\d+:in .cg1__D'/]

        expres.each_with_index do |expre, i|
          expect(log_ents[2].details['err_stack'][i]).to match(expre)
        end
      end
    end
  end
end
