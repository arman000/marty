require 'spec_helper'

module Marty::RuleSpec
  describe "Rule" do
    before(:all) do
      @save_file = "/tmp/save_#{Process.pid}.psql"
      save_clean_db(@save_file)
      Marty::Script.load_scripts
      Marty::Config['RULEOPTS_MYRULE']={'simple_result'=>{},
                                        'computed_value'=>{},
                                        'final_value'=>{},
                                       }
      Marty::Config['RULEOPTS_XYZ']={'bvlength'=>{},
                                     'bv'=>{},
                                    }
    end
    after(:all) do
      restore_clean_db(@save_file)
    end
    before(:each) do
      marty_whodunnit
      dt = DateTime.parse('2017-1-1')
      p = File.expand_path('../../fixtures/csv/rule', __FILE__)
      [Marty::DataGrid, Gemini::XyzRule, Gemini::MyRule].each do |klass|
        f = "%s/%s.csv" % [p, klass.to_s.sub(/(Gemini|Marty)::/,'')]
        Marty::DataImporter.do_import(klass, File.read(f), dt, nil, nil, ",")
      end
      Marty::Tag.do_create('2017-01-01', 'tag')
    end
    context "validation" do
      subject do
        guards = (@g_array   ? {"g_array"   =>@g_array}   : {}) +
                 (@g_single  ? {"g_single"  =>@g_single}  : {}) +
                 (@g_string  ? {"g_string"  =>@g_string}  : {}) +
                 (@g_bool    ? {"g_bool"    =>@g_bool}    : {}) +
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
        exp = /Computed - Error in rule 'testrule' field 'computed_guards': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid2"}
        exp = /Computed - Error in rule 'testrule' field 'results': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 2" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid1","grid3"=>"DataGrid3"}
        exp = /Computed - Error in rule 'testrule' field 'results': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 3" do
        @rule_type = "SimpleRule"
        @results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"DataGrid1","grid2"=>"DataGrid1","grid3"=>"DataGrid1"}
        exp = /Computed - Error in rule 'testrule' field 'results': syntax error/
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
        expect(vals).to eq([["Rule1", "different"],
                            ["Rule2", "string default"],
                            ["Rule2a", "string default"],
                            ["Rule2b", "string default"],
                            ["Rule3", "string default"],
                            ["Rule4", "string default"],
                            ["Rule5", "foo"]])
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
        exp = /Computed - Error in rule 'testrule' field 'results': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "rule script stuff overrides 1" do
        @rule_type = 'XRule'
        @computed_guards = {"abc"=>"true", "xyz_guard"=> "err err err"}
        exp = /Computed - Error in rule 'testrule' field 'xyz': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "rule script stuff overrides 2" do
        @rule_type = 'XRule'
        @computed_guards = {"abc"=>"err err err", "xyz_guard"=> "xyz_param"}
        exp = /Computed - Error in rule 'testrule' field 'computed_guards': syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "rule script stuff overrides 3" do
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
        expect(lookup.to_a.count).to eq(3)
        expect(lookup.map{|l|l.name}.to_set).to eq(Set["Rule2","Rule2a","Rule2b"])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'ComplexRule',
                                            'other_flag'=>false},
                                            {})
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
                                            {'g_bool'=>false, "g_range"=>75,
                                             'g_integer'=>10})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_type'=>'SimpleRule'}, {})
        expect(lookup.to_a.count).to eq(4)
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2017-3-1 02:00:00"},
                                            {})
        expect(lookup.to_a.count).to eq(5)
        expect(lookup.pluck(:name).to_set).to eq(Set["Rule1", "Rule2", "Rule2a",
                                                     "Rule2b", "Rule3"])
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
      it "computed guards work" do
        c = complex.compute({"pt"=>Time.zone.now,
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
        expect{simple.compute({"pt"=>Time.now})}.to raise_error(/hi mom/)
        # simple2a should return results without evaluation (they are all fixed)
        expect(simple2a.compute({"pt"=>Time.zone.now})).to eq(
                                       {"simple_result"=>"b value",
                                        "sr2"=>true,
                                        "sr3"=>123})
        # simple2b should return grid results without evaluation
        expect(simple2b.compute({"pt"=>Time.zone.now,
                                 'param1'=> 66,
                                 'param2'=>'abc',
                                 'paramb'=>false})).to eq({"grid1_grid"=>3,
                                                           "grid2_grid"=>1300})

      end
      it "returns computed results" do
        c = complex.compute({"pt"=>Time.zone.now,
                             'param1'=> 66,
                             'param2'=>'abc',
                             'paramb'=>false})
        expect(c).to eq({"simple_result"=>"c value",
                         "computed_value"=>19, "grid1_grid"=>3, "grid2_grid"=>1300})
      end
      it "returns computed results (with delorean import)" do
        c = xyz.compute({"pt"=>Time.zone.now+1,
                         "p1"=>12,
                         "p2"=>3,
                         "flavor"=>"cherry"})
        expect(c).to eq({"bvlength"=>13,"bv"=>"cherry --> 36",
                         "grid1_grid"=>19})
      end
      it "grids embedded in result work properly and receive prior attrs" do
        v = altgridmethod.compute({"pt"=>Time.zone.now,
                                   'param1'=> 45,
                                   'param2' => 1})
        expect(v["final_value"]).to eq(15)
      end
    end
  end
end
