require 'spec_helper'

module Marty::RuleSpec
  describe "Rule" do
    before(:all) do
      @save_file = "/tmp/save_#{Process.pid}.psql"
      save_clean_db(@save_file)
      Marty::Script.load_scripts
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
        attrs = (@subtype ?  {"subtype"     =>@subtype}   : {}) +
                (@start_dt ? {"start_dt"    =>@start_dt}  : {}) +
                (@end_dt ?   {"start_dt"    =>@end_dt}    : {})
        guards = (@g_array   ? {"g_array"   =>@g_array}   : {}) +
                 (@g_single  ? {"g_single"  =>@g_single}  : {}) +
                 (@g_string  ? {"g_string"  =>@g_string}  : {}) +
                 (@g_bool    ? {"g_bool"    =>@g_bool}    : {}) +
                 (@g_range   ? {"g_range"   =>@g_range}   : {}) +
                 (@g_integer ? {"g_integer" =>@g_integer} : {})
        Gemini::MyRule.create!(name: "testrule",
                               attrs: attrs,
                               simple_guards: guards,
                               computed_guards: @computed_guards || {},
                               grids: @grids || {},
                               computed_results: @computed_results || {}
                              )
      end
      it "detects type errors" do
        @subtype = 'SimpleRule'
        @start_dt = "abc"
        expect{subject}.to raise_error(/Attributes - Wrong type for 'start_dt'/)
      end
      it "detects value errors 1" do
        @subtype = "SimpleRule"
        @g_array = ["G1V1", "abcd"]
        expect{subject}.to raise_error(/Guards - Bad value 'abcd' for 'g_array'/)
      end
      it "detects value errors 2" do
        @subtype = "SimpleRule"
        @g_array = ["G1V1", "xyz", "abc"]
        exp = /Guards - Bad values 'xyz', 'abc' for 'g_array'/
        expect{subject}.to raise_error(exp)
      end
      it "detects arity errors 1" do
        @subtype = "SimpleRule"
        @g_single = ["G2V1","G2V2"]
        exp = /Guards - Wrong arity for 'g_single' .expected single got multi./
        expect{subject}.to raise_error(exp)
      end
      it "detects arity errors 2" do
        @subtype = "SimpleRule"
        @g_array = "G1V1"
        exp = /Guards - Wrong arity for 'g_array' .expected multi got single./
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed guards" do
        @subtype = "SimpleRule"
        @computed_guards = {"guard1"=> "zvjsdf12.z8*"}
        exp = /Computed - Error in field computed_guards: syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results" do
        @subtype = "SimpleRule"
        @computed_results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"Grid1","grid2"=>"Grid2"}
        exp = /Computed - Error in field computed_results: syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 2" do
        @subtype = "SimpleRule"
        @computed_results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"Grid1","grid2"=>"Grid1","grid3"=>"Grid3"}
        exp = /Computed - Error in field computed_results: syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "detects errors in computed results 3" do
        @subtype = "SimpleRule"
        @computed_results = {"does_not_compute"=> "zvjsdf12.z8*"}
        @grids = {"grid1"=>"Grid1","grid2"=>"Grid1","grid3"=>"Grid1"}
        exp = /Computed - Error in field computed_results: syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "reports bad grid names" do
        @subtype = "SimpleRule"
        @grids = {"grid1"=>"xyz","grid2"=>"Grid2","grid3"=>"Grid1"}
        exp = /Grids - Bad grid name 'xyz' for 'grid1'/
        expect{subject}.to raise_error(exp)
      end
    end
    context "validation (xyz type)" do
      subject do
        attrs = (@subtype ?  {"subtype"     =>@subtype}   : {}) +
                (@start_dt ? {"start_dt"    =>@start_dt}  : {}) +
                (@end_dt ?   {"start_dt"    =>@end_dt}    : {})
        Gemini::XyzRule.create!(name: "testrule",
                                attrs: attrs,
                                simple_guards: {},
                               computed_guards: @computed_guards || {},
                               grids: @grids || {},
                               computed_results: @computed_results || {}
                              )
      end
      it "detects script errors" do
        @subtype = 'XRule'
        @computed_results = {"x"=>"zx sdf wer"}
        exp = /Computed - Error in field computed_results: syntax error/
        expect{subject}.to raise_error(exp)
      end
      it "no error" do
        @subtype = 'XRule'
        @computed_results = {"x"=>"1"}
        expect{subject}.not_to raise_error
      end
    end

    context "lookups" do
      it "matches" do
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_array'=>'G1V3'})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule',
                                            'other_flag'=>true},
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule2")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'ComplexRule',
                                            'other_flag'=>false},
                                            {})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule3")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'ComplexRule'},
                                            {'g_string'=>'def'})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule3")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'ComplexRule'},
                                            {'g_string'=>'abc'})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>25})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule2")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75,
                                             'g_integer'=>11})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_bool'=>true, "g_range"=>75,
                                             'g_integer'=>10})
        expect(lookup.to_a.count).to eq(1)
        expect(lookup.first.name).to eq("Rule1")
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'},
                                            {'g_bool'=>false, "g_range"=>75,
                                             'g_integer'=>10})
        expect(lookup).to eq([])
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'subtype'=>'SimpleRule'}, {})
        expect(lookup.to_a.count).to eq(2)
        lookup = Gemini::MyRule.get_matches('infinity',
                                            {'rule_dt'=>"2017-3-1 02:00:00"},
                                            {})
        expect(lookup.to_a.count).to eq(3)
        expect(lookup.pluck(:name).to_set).to eq(Set["Rule1","Rule2","Rule3"])
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
                                            {'subtype'=>'ComplexRule'},
                                            {'g_string'=>'def'}).first }
      let(:xyz) { Gemini::XyzRule.get_matches('infinity',
                                              {'subtype'=>'ZRule'},
                                              {'g_integer'=> 2}).first }
      let(:simple) {
        Gemini::MyRule.get_matches('infinity',
                                   {'subtype'=>'SimpleRule'},
                                   {'g_bool'=>true, "g_range"=>25}).first }
      it "computed guards work" do
        c = complex.compute({"pt"=>Time.zone.now,
                             'param2'=>'def'})
        expect(c).to eq({"cguard2"=>false})
      end
      it "returns simple results" do
        expect(simple.simple_results["simple_result"]).to eq("b value")
      end
      it "returns computed results" do
        c = complex.compute({"pt"=>Time.zone.now,
                             'param1'=> 66,
                             'param2'=>'abc',
                             'paramb'=>false})
        expect(c).to eq({"computed_value"=>19, "grid1"=>3, "grid2"=>1300})
      end
      it "returns computed results (with delorean import)" do
        c = xyz.compute({"pt"=>Time.zone.now+1,
                         "p1"=>12,
                         "p2"=>3,
                         "flavor"=>"cherry"})
        expect(c).to eq({"bvlength"=>13,"bv"=>"cherry --> 36",
                         "grid1"=>19})
      end
    end
  end
end
