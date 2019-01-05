require 'spec_helper'

module Marty::RuleSpec
  describe "Rule" do
    before(:all) do
      @save_file = "/tmp/save_#{Process.pid}.psql"
      save_clean_db(@save_file)
      marty_whodunnit
      Marty::Script.load_scripts
      @ruleopts_myrule=['simple_result', 'computed_value', 'final_value',
                        'grid_sum', 'c1', 'sr2']
      @ruleopts_xyz=['bvlength', 'bv']

      # must go up  because Rails root is in spec/dummy
      f = '../fixtures'
      @rule_data = Rails.root.join("#{f}/csv/rule")
      @json_data = Rails.root.join("#{f}/json")
    end
    after(:all) do
      restore_clean_db(@save_file)
    end
    before(:each) do
      dt = DateTime.parse('2017-1-1')
      [Marty::DataGrid, Gemini::XyzRule, Gemini::MyRule].each do |klass|
        f = @rule_data.join(klass.to_s.sub(/(Gemini|Marty)::/,'') + ".csv")
        Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ",")
      end
      Marty::Tag.do_create('2017-01-01', 'tag')
    end
    context "validation" do
      subject do
        guards = (@g_array   ? {"g_array"   =>@g_array}   : {}) +
                 (@g_single  ? {"g_single"  =>@g_single}  : {}) +
                 (@g_string  ? {"g_string"  =>@g_string}  : {}) +
                 (@g_bool.nil?     ? {} : {"g_bool"     => @g_bool})     +
                 (@g_nullbool.nil? ? {} : {"g_nullbool" => @g_nullbool}) +
                 (@g_range   ? {"g_range"   =>@g_range}   : {}) +
                 (@g_integer ? {"g_integer" =>@g_integer} : {})
        Gemini::MyRule.create!(name: "testrule",
                               rule_type: @rule_type,
                               start_dt: @start_dt || '2013-1-1',
                               end_dt:   @end_dt,
                               simple_guards: guards,
                               computed_guards: @computed_guards || {},
                               grids: @grids || {},
                               results: @results || {}
                              )
      end
      it "detects type errors" do
        @rule_type = 'SimpleRule'
        @g_integer = "abc"
        expect{subject}.to raise_error(/Guards - Wrong type for 'g_integer'/)
      end
      it "detects value errors 1" do
        @rule_type = "SimpleRule"
        @g_array = ["G1V1", "abcd"]
        expect{subject}.to raise_error(/Guards - Bad value 'abcd' for 'g_array'/)
      end
      it "detects value errors 2" do
        @rule_type = "SimpleRule"
        @g_array = ["G1V1", "xyz", "abc"]
        exp = /Guards - Bad values 'xyz', 'abc' for 'g_array'/
        expect{subject}.to raise_error(exp)
      end
      it "detects arity errors 1" do
        @rule_type = "SimpleRule"
        @g_single = ["G2V1","G2V2"]
        exp = /Guards - Wrong arity for 'g_single' .expected single got multi./
        expect{subject}.to raise_error(exp)
      end
      it "detects arity errors 2" do
        @rule_type = "SimpleRule"
        @g_array = "G1V1"
        exp = /Guards - Wrong arity for 'g_array' .expected multi got single./
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed guards" do
        @rule_type = "SimpleRule"
        @computed_guards = {"guard1"=> "zvjsdf12.z8*"}
        exp = /Computed - Error in rule 'testrule' field 'computed_guards': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid2"}
        exp = /Computed - Error in rule 'testrule' field 'results': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 2" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid1","grid3"=>"DataGrid3"}
        exp = /Computed - Error in rule 'testrule' field 'results': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 3" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid1","grid3"=>"DataGrid1"}
        exp = /Computed - Error in rule 'testrule' field 'results': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "reports bad grid names" do
        @rule_type = "SimpleRule"
        @grids = {"grid1"=>"xyz","grid2"=>"DataGrid2","grid3"=>"DataGrid1"}
        exp = /Grids - Bad grid name 'xyz' for 'grid1'/
        expect{subject}.to raise_error(exp)
      end
      it "sets guard defaults correctly" do
        vals = Gemini::MyRule.all.map do
          |r|
          [r.name, r.simple_guards["g_has_default"]]
        end
        expect(vals.sort).to eq([["Rule1", "different"],
                            ["Rule2", "string default"],
                            ["Rule2a", "string default"],
                            ["Rule2b", "string default"],
                            ["Rule2c", "string default"],
                            ["Rule3", "string default"],
                            ["Rule4", "string default"],
                            ["Rule5", "foo"]].sort)
      end
    end
    context "validation (xyz type)" do
      subject do
        r=Gemini::XyzRule.create!(name: "testrule",
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
      it "detects script errors" do
        @rule_type = 'XRule'
        @results = {"x"=>"zx sdf wer"}
        exp = /Computed - Error in rule 'testrule' field 'results': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      xit "rule script stuff overrides 1" do
        @rule_type = 'XRule'
        @computed_guards = {"abc"=>"true", "xyz_guard"=> "err err err"}
        exp = /Computed - Error in rule 'testrule' field 'xyz': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      xit "rule script stuff overrides 2" do
        @rule_type = 'XRule'
        @computed_guards = {"abc"=>"err err err", "xyz_guard"=> "xyz_param"}
        exp = /Computed - Error in rule 'testrule' field 'computed_guards': Syntax error/
        expect{subject}.to raise_error(exp)
      end
      xit "rule script stuff overrides 3" do
        @rule_type = 'XRule'
        @computed_guards = {"abc"=>"true", "xyz_guard"=> "!xyz_param"}
        rule = subject
        expect(rule.compute_xyz('infinity',true)).to be false
        expect(rule.compute_xyz('infinity',false)).to be true
      end
      it "no error" do
        @rule_type = 'XRule'
        @results = {"x"=>"1"}
        expect{subject}.not_to raise_error
      end
    end

    context "lookups" do
      it "matches" do
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_array'=>'G1V3'})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule',

                                            'other_flag'=>true},
                                            {})
        expect(lookup.to_a.count).to eq(4)
        expect(lookup.map{|l|l.name}.to_set).to eq(Set["Rule2","Rule2a",
                                                       "Rule2b", "Rule2c"])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule',
                                            'other_flag'=>false},
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule3")
        # bool false matches bool nil
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule',
                                            'other_flag'=>false},
                                            {'g_bool'=>false})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule3")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule'},
                                            {'g_string'=>'def'})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule3")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule'},
                                            {'g_string'=>'abc'})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>25,
                                             'g_integer'=>99})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule2a")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75,
                                             'g_integer'=>11})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75,
                                             'g_integer'=>10})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'},
                                            {'g_bool'=>false, "g_range"=>25,
                                             'g_integer'=>10})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule2c")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'}, {})
        expect(lookup.to_a.count).to eq(5)
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2017-3-1 02:00:00"},
                                            {})
        expect(lookup.to_a.count).to eq(6)
        expect(lookup.pluck(:name).to_set).to eq(Set["Rule1", "Rule2", "Rule2a",
                                                   "Rule2b", "Rule2c", "Rule3"])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2017-4-1 16:00:00"},
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.pluck(:name).first).to eq("Rule4")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2016-12-31"}, {})
        expect(lookup.to_a).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2017-5-1 00:00:01"}, {})
        expect(lookup.to_a).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity', {},
                                            {"g_bool_def"=>false,
                                             "g_nbool_def"=>true})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.pluck(:name).first).to eq("Rule1")
      end
    end
    context "rule multi compute" do
     it "does" do
       ruleh_a = Gemini::XyzRule.get_matches('infinity',
                                             {"rule_type" => 'ZRule'},
                                             {"g_string"=> "eee"}).
              order(:group_id).map(&:self_as_hash)
        md_opts = ['bvlen', 'bv']
        count = 0
        allow_any_instance_of(Marty::ScriptSet).
          to receive(:parse_check).and_wrap_original {|m, *args|
          count += 1
          m.call(*args)
        }
        x = nil
        t1 = Benchmark.measure do
          x = Marty::DeloreanRule.multi_compute(Gemini::XyzRule, ruleh_a,
                                                md_opts,
                                                'infinity',
                                                {"p1"=>12,
                                                 "p2"=>15,
                                                 "flavor"=> "cherry"},
                                                "xyz_multi")
        end
        expect(count).to eq(1)
        x_dtstrs = x.map do |r|
          Hash[r.map do |k, v|
                 [k, k.ends_with?("_dt") ? v.to_s : v]
               end]
        end
        exp = JSON.parse(File.read(@json_data.join("rule_multi.json")))
        comp = struct_compare(x_dtstrs, exp, "ignore" => ["id", "group_id"])
        binding.pry if comp and ENV['PRY'] == 'true'
        expect(comp).to be nil

        # recompute with different rules
        ruleh_a.pop
        t2 = Benchmark.measure do
          x = Marty::DeloreanRule.multi_compute(Gemini::XyzRule, ruleh_a,
                                                md_opts,
                                                'infinity',
                                                {"p1"=>12,
                                                 "p2"=>15,
                                                 "flavor"=> "cherry"},
                                                "xyz_multi")
        end
        expect(count).to eq(1)
        x_dtstrs = x.map do |r|
          Hash[r.map do |k, v|
                 [k, k.ends_with?("_dt") ? v.to_s : v]
               end]
        end
        exp = JSON.parse(File.read(@json_data.join("rule_multi2.json")))
        comp = struct_compare(x_dtstrs, exp, "ignore" => ["id", "group_id"])
        binding.pry if comp and ENV['PRY'] == 'true'
        expect(comp).to be nil
        expect(t1.real / t2.real).to be > 20
      end
    end
    context "rule compute" do
      let(:complex) { Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule'},
                                            {'g_string'=>'def'}).first }
      let(:xyz) { Gemini::XyzRule.get_matches('infinity',
                                              {'rule_type'=>'ZRule'},
                                              {'g_integer'=> 2}).first }
      let(:simple) {
        Gemini::MyRule.get_matches('infinity',
                                   {'rule_type'=>'SimpleRule'},
                                   {'g_bool'=>true, "g_range"=>25}).first }
      let(:simple2a) {
        Gemini::MyRule.get_matches('infinity',
                                   {'rule_type'=>'SimpleRule'},
                                   {'g_bool'=>true, "g_integer"=>99}).first }
      let(:simple2b) {
        Gemini::MyRule.get_matches('infinity',
                                   {'rule_type'=>'SimpleRule'},
                                   {'g_bool'=>true, "g_integer"=>999}).first }
      let(:altgridmethod) {
        Gemini::MyRule.get_matches('infinity',
                                   {'rule_type'=>'ComplexRule'},
                                   {"g_integer"=>3757}).first }
      let(:gridcomputedname) {
        Gemini::MyRule.get_matches('infinity',
                                   {'rule_type'=>'ComplexRule'},
                                   {"g_string"=>"Hi Mom",
                                    "g_integer"=>11}).first }
      it "computed guards work" do
        c = complex.compute(@ruleopts_myrule, {"pt"=>Time.zone.now,
                                               'param2'=>'def'})
        expect(c).to eq({"cguard2"=>false})
      end
      it "returns simple results via #fixed_results" do
        expect(simple.fixed_results["simple_result"]).to eq("b value")
        expect(simple.fixed_results["sr2"]).to eq(true)
        expect(simple.fixed_results["sr3"]).to eq(123)
        ssq = "string with single quotes"
        expect(simple.fixed_results["single_quote"]).to eq(ssq)
        swh = " string that contains a # character"
        expect(simple.fixed_results["stringwithhash"]).to eq(swh)
        expect(simple.fixed_results.count).to eq(5)
        allow_any_instance_of(Delorean::Engine).
          to receive(:evaluate).and_raise('hi mom')
        expect{simple.compute(@ruleopts_myrule,
                              {"pt"=>Time.now})}.to raise_error(/hi mom/)
        # simple2a should return results without evaluation (they are all fixed)
        expect(simple2a.compute(@ruleopts_myrule, {"pt"=>Time.zone.now})).to eq(
                                       {"simple_result"=>"b value",
                                        "sr2"=>true,
                                       })
        # simple2b should return grid results without evaluation
        expect(simple2b.compute(@ruleopts_myrule,
                                {"pt"=>Time.zone.now,
                                 'param1'=> 66,
                                 'param2'=>'abc',
                                 'paramb'=>false})).
          to eq({"grid1_grid_result"=>3,
                 "grid2_grid_result"=>1300})

      end
      it "returns computed results" do
        c = complex.compute(@ruleopts_myrule, {"pt"=>Time.zone.now,
                                               'param1'=> 66,
                                               'param2'=>'abc',
                                               'paramb'=>false})
        expect(c).to eq({"simple_result"=>"c value",
                         "computed_value"=>19, "grid1_grid_result"=>3,
                         "grid2_grid_result"=>1300})
      end
      it "returns computed results (with delorean import)" do
        c = xyz.compute(@ruleopts_xyz, {"pt"=>Time.zone.now+1,
                                        "p1"=>12,
                                        "p2"=>3,
                                        "flavor"=>"cherry"})
        expect(c).to eq({"bvlength"=>13,"bv"=>"cherry --> 36",
                         "grid1_grid_result"=>19})
      end
      it "reports bad grid name" do
        exp = Regexp.new("Error .results. in rule '\\d+:Rule4': "\
                         "DataGridX grid not found")
        expect{gridcomputedname.compute(@ruleopts_myrule,
                                        {"pt"=>Time.zone.now,
                                         'param1'=> 66,
                                         'param2'=>'abc',
                                         'paramb'=>false})}.to raise_error(exp)
      end
      it "grids embedded in result work properly and receive prior attrs" do
        v = altgridmethod.compute(@ruleopts_myrule, {"pt"=>Time.zone.now,
                                                     'param1'=> 45,
                                                     'param2' => 1})
        expect(v["final_value"]).to eq(15)
      end
      it "exceptions/logging" do
        r6, r7, r8 = [6, 7, 8].map do |i|
          Gemini::XyzRule.get_matches('infinity',
                                      {'rule_type'=>'ZRule'},
                                      {'g_integer'=>i}).first
        end
        pt = Time.zone.now+1
        input = {"pt"=>pt,
                 "p1"=>12,
                 "p2"=>3,
                 "flavor"=>"cherry"}
        v1 = r6.compute(@ruleopts_xyz, input)
        begin
          v2 = r7.compute(@ruleopts_xyz, input)
        rescue Marty::DeloreanRule::ComputeError => e
          exp = 'no implicit conversion of Integer into String'
          expect(e.message).to include(exp)
          expres = [/DELOREAN__XyzRule_\d+_1483228800.0:23:in .+'/,
                 /DELOREAN__XyzRule_\d+_1483228800.0:23:in .tmp_var4__D'/,
                 /DELOREAN__XyzRule_\d+_1483228800.0:27:in .bv__D'/]
          expres.each_with_index do |expre, i|
            expect(e.backtrace[i]).to match(expre)
          end
          expect(e.input).to eq(input + {'dgparams__'=>input})
          expect(e.section).to eq('results')
        end
        begin
          v2 = r8.compute(@ruleopts_xyz, input)
        rescue Marty::DeloreanRule::ComputeError => e
          exp = 'divided by 0'
          expect(e.message).to include(exp)
          expres = [%r(DELOREAN__XyzRule_\d+_1483228800.0:5:in ./'),
                 /DELOREAN__XyzRule_\d+_1483228800.0:5:in .cg1__D'/]
          expres.each_with_index do |expre, i|
            expect(e.backtrace[i]).to match(expre)
          end
          expect(e.input).to eq(input)
          expect(e.section).to eq('computed_guards')
        end
        log_ents = Marty::Log.all
        expect(log_ents.map{|le|le.message}).to eq(['Rule Log ZRule6',
                                                   'Rule Log ZRule7',
                                                   'Rule Log ZRule8'])
        ptjson = pt.as_json
        exp = {"input"=>{"p1"=>12, "p2"=>3,
                         "pt"=>ptjson,
                         "flavor"=>"cherry"},
               "dgparams"=>{"p1"=>12, "p2"=>3,
                            "pt"=>ptjson,
                            "flavor"=>"cherry"},
               "gr_keys"=>["grid1_grid_result"],
               "res_hash"=>
               {"bv"=>"a stringa stringa stringa stringa stringa stringa stringa "\
                "stringa stringa stringa stringa stringa stringa stringa "\
                "stringa stringa stringa stringa stringa stringa stringa "\
                "stringa stringa stringa stringa string",
                "grid1_grid_result"=>19}}
        expect(log_ents[0].details).to eq(exp)
        exp = {"input"=>{"p1"=>12, "p2"=>3,
                         "pt"=>ptjson,
                         "flavor"=>"cherry"},
               "cg_hash"=>{"some_guard"=>true},
               "gr_keys"=>["grid1_grid_result"],
               "dgparams"=>{"p1"=>12, "p2"=>3,
                            "pt"=>ptjson,
                            "flavor"=>"cherry"},
               "res_keys"=>["bv", "grid1_grid_result"],
               "err_section"=>"results",
               "err_message"=>"no implicit conversion of Integer into String"}
        expect(log_ents[1].details.except('err_stack')).to eq(exp)
        expres = [/DELOREAN__XyzRule_\d+_1483228800.0:23:in .+'/,
               /DELOREAN__XyzRule_\d+_1483228800.0:23:in .tmp_var4__D'/,
               /DELOREAN__XyzRule_\d+_1483228800.0:27:in .bv__D'/]
        expres.each_with_index do |expre, i|
          expect(log_ents[1].details['err_stack'][i]).to match(expre)
        end
        exp = {"input"=>{"p1"=>12, "p2"=>3,
                         "pt"=>ptjson,
                         "flavor"=>"cherry"},
               "cg_keys"=>["cg1"],
               "dgparams"=>{"p1"=>12, "p2"=>3,
                            "pt"=>ptjson,
                            "flavor"=>"cherry"},
               "err_section"=>"computed_guards",
               "err_message"=>"divided by 0"}
        expect(log_ents[2].details.except('err_stack')).to eq(exp)
        expres = [%r(DELOREAN__XyzRule_\d+_1483228800.0:5:in ./'),
               /DELOREAN__XyzRule_\d+_1483228800.0:5:in .cg1__D'/]
        expres.each_with_index do |expre, i|
          expect(log_ents[2].details['err_stack'][i]).to match(expre)
        end
      end
    end
  end
end
