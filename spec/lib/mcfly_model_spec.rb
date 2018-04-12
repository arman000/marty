require "spec_helper"

module Marty

entities =<<EOF
name
PLS
EOF
bud_cats =<<EOF
name
Conv Fixed 30
Conv Fixed 20
EOF

fannie_bup =<<EOF
entity	bud_category	note_rate	buy_up	buy_down	settlement_mm	settlement_yy
	Conv Fixed 30	2.250	4.42000	7.24000	12	2012
	Conv Fixed 30	2.375	4.42000	7.24000	12	2012
	Conv Fixed 30	2.500	4.41300	7.22800	12	2012
	Conv Fixed 30	2.625	4.37500	7.16200	12	2012
	Conv Fixed 30	2.750	4.32900	7.09300	12	2012
	Conv Fixed 20	2.875	4.24800	6.95900	12	2012
	Conv Fixed 20	2.875	4.24800	6.95900	11	2012
PLS	Conv Fixed 30	2.250	5.42000	8.24000	12	2012
PLS	Conv Fixed 30	2.375	5.42000	8.24000	12	2012
PLS	Conv Fixed 30	2.500	5.41300	8.22800	12	2012
PLS	Conv Fixed 30	2.625	5.37500	8.16200	12	2012
PLS	Conv Fixed 30	2.750	5.32900	8.09300	12	2012
PLS	Conv Fixed 20	2.875	5.24800	7.95900	12	2012
PLS	Conv Fixed 20	2.875	5.24800	7.95900	11	2012
EOF

script =<<EOF
A:
    pt        =?
    entity    =?
    note_rate =?
    e_id      =?
    bc_id     =?

    extra = {"include_attrs": ["settlement_mm", "settlement_yy"],
             "link_attrs": {"entity": "name",
                            "bud_category": "name"}}
    ex2 = {"include_attrs": ["settlement_mm", "settlement_yy", "entity_id",
                             "bud_category_id"]}

    lookup            = Gemini::FannieBup.lookup(  pt, entity, note_rate)
    lookup_extra      = Gemini::FannieBup.lookup(  pt, entity, note_rate, extra)

    clookup     = Gemini::FannieBup.clookup( pt, entity, note_rate)

    lookupn            = Gemini::FannieBup.lookupn( pt, entity, note_rate)
    lookupn_extra      = Gemini::FannieBup.lookupn(  pt, entity, note_rate, ex2)

    clookupn    = Gemini::FannieBup.clookupn(pt, entity, note_rate)

    a_func = Gemini::FannieBup.a_func('infinity', e_id, bc_id)
    a_func_extra = Gemini::FannieBup.a_func('infinity', e_id, bc_id, ex2)
    b_func = Gemini::FannieBup.b_func('infinity', e_id, bc_id, 12)
    b_func_extra = Gemini::FannieBup.b_func('infinity', e_id, bc_id, 12, extra)
    ca_func = Gemini::FannieBup.ca_func('infinity', e_id, bc_id, ex2)

EOF
errscript =<<EOF
Err:
    pt        =?
    entity    =?
    note_rate =?
    result = Gemini::FannieBup.%s(pt, entity, note_rate)
EOF
errscript2 =<<EOF
Err:
    pt    =?
    e_id  =?
    bc_id =?
    result = Gemini::FannieBup.%s(pt, e_id, bc_id)
EOF
errscript3 =<<EOF
Err:
    pt    =?
    e_id  =?
    bc_id =?
    mm    =?
    result = Gemini::FannieBup.%s(pt, e_id, bc_id, mm)
EOF

  describe 'McflyModel' do
    before(:all) do
      @clean_file = "/tmp/clean_#{Process.pid}.psql"
      save_clean_db(@clean_file)
      marty_whodunnit
      dt = Date.today
      Marty::DataImporter.do_import_summary(Gemini::Entity, entities)
      Marty::DataImporter.do_import_summary(Gemini::BudCategory, bud_cats)
      Marty::DataImporter.do_import_summary(Gemini::FannieBup, fannie_bup)
      Marty::Script.load_script_bodies(
        {
          "AA" => script,
        }, dt)
      @errs = ['E1', 'lookup_p',
               'E2', 'clookup_p',
               'E3', 'lookupn_p',
               'E4', 'clookupn_p']

      @errs.in_groups_of(2) do |name, fn|
        Marty::Script.load_script_bodies(
        {
          name => (errscript % fn),
        }, Date.today)
      end

      Marty::Script.load_script_bodies({'E5'=>(errscript2 % 'a_func_p')}, dt)
      Marty::Script.load_script_bodies({'E6'=>(errscript3 % 'b_func_p')}, dt)

      @engine = Marty::ScriptSet.new.get_engine("AA")
    end
    after(:all) do
      restore_clean_db(@clean_file)
      Marty::ScriptSet.clear_cache
    end
    let(:params) {{"pt"        =>'infinity',
                   "entity"    => Gemini::Entity.all.first,
                   "note_rate" => 2.875}}
    it "lookup mode default" do
      a1 = @engine.evaluate("A", "lookup", params)
      a2 = @engine.evaluate("A", "clookup", params)
      expect(a1).to eq(a2)                            # cache/non return same
      expect(a1.class).to eq(OpenStruct)              # mode default so return OS
      expect(a2.class).to eq(OpenStruct)

      # check that keys are non mcfly non uniqueness
      expect(a1.to_h.keys.to_set).to eq(Set[:buy_up, :buy_down])
    end

    it "lookup non generated" do
      # a1-a3 will be AR Relations
      # b1-b2 will be OpenStructs because the b fns return #first
      e_id = Gemini::Entity.where(name: "PLS").first.id
      bc_id = Gemini::BudCategory.where(name: "Conv Fixed 20").first.id
      p = {"e_id"=>e_id, "bc_id"=>bc_id}
      a1 = @engine.evaluate("A", "a_func", p)
      a2 = @engine.evaluate("A", "ca_func", p)
      a3 = @engine.evaluate("A", "a_func_extra", p)
      b1 = @engine.evaluate("A", "b_func", p)
      b2 = @engine.evaluate("A", "b_func_extra", p)

      # all return relations
      expect(ActiveRecord::Relation === a1).to be_truthy
      expect(ActiveRecord::Relation === a2).to be_truthy
      expect(ActiveRecord::Relation === a3).to be_truthy
      expect(ActiveRecord::Base === a1.first).to be_truthy
      expect(ActiveRecord::Base === a2.first).to be_truthy
      expect(ActiveRecord::Base === a3.first).to be_truthy

      expect(a1.to_a.count).to eq(2)
      expect(a2.to_a.count).to eq(2)
      expect(a3.to_a.count).to eq(2)

      # a1 lookup did not include extra attrs
      expect(a1.first.attributes.keys.to_set).to eq(Set["id", "buy_up", "buy_down"])

      # a2 and a3 did
      s = Set["id", "entity_id", "bud_category_id",  "buy_up", "buy_down",
              "settlement_mm", "settlement_yy"]
      expect(a2.first.attributes.keys.to_set).to eq(s)
      expect(a3.first.attributes.keys.to_set).to eq(s)

      # a1 is AR but still missing the FK entity_id so will raise
      expect{a1.first.entity}.to raise_error(/missing attribute: entity_id/)

      # a3 included those so can access them
      expect(a3.first.entity.name).to eq('PLS')
      expect(a3.first.bud_category.name).to eq('Conv Fixed 20')

      expect(b1.class).to eq(OpenStruct)
      expect(b2.class).to eq(OpenStruct)

      # make sure b1-b2 have correct keys and extra stuff
      expect(b1.to_h.keys.to_set).to eq(Set[:buy_up, :buy_down])
      expect(b2.to_h.keys.to_set).to eq(
               Set[:buy_up, :buy_down, :settlement_mm, :settlement_yy,
                :entity, :bud_category])
      expect(b2.entity.name).to eq('PLS')
      expect(b2.bud_category.name).to eq('Conv Fixed 20')
    end
    it "lookup extra values" do
      a2 = @engine.evaluate("A", "lookup_extra", params)
      expect(a2.class).to eq(OpenStruct)

      # check that extra values are there
      expect(a2.to_h.keys.to_set).to eq(Set[:buy_up, :buy_down, :settlement_mm,
                                            :settlement_yy, :entity,
                                            :bud_category])
      # check that linked values are there
      expect(a2.entity.name).to eq("PLS")
      expect(a2.bud_category.name).to eq("Conv Fixed 20")
    end
    it "lookup mode nil extra values" do
      all = @engine.evaluate("A", "lookupn_extra", params)

      # mode nil always returns AR
      expect(ActiveRecord::Relation === all).to be_truthy

      # check keys returned
      all.each do |a2|
        expect(a2.attributes.keys.to_set).to eq(
                       Set["id", "buy_up", "buy_down", "settlement_mm",
                           "settlement_yy", "entity_id", "bud_category_id"])
        if a2.entity_id
          expect(a2.entity.name).to eq("PLS")
          expect(ActiveRecord::Base === a2.entity).to be_truthy
          expect(a2.bud_category.name).to eq("Conv Fixed 20")
          expect(ActiveRecord::Base === a2.bud_category).to be_truthy
        end
      end
    end
    it "lookup mode nil" do
      # make sure ARs are returned
      a1 = @engine.evaluate("A", "lookupn", params)
      a2 = @engine.evaluate("A", "clookupn", params)
      expect(a1).to eq(a2)
      expect(ActiveRecord::Relation === a1).to be_truthy
      expect(a1.to_a.count).to eq(4)
    end
    it "private methods can't be called by delorean" do
      # generated methods
      aggregate_failures "errors" do
        @errs.in_groups_of(2) do |name, fn|
          err = /Too many args to #{fn}/
          expect{Marty::ScriptSet.new.get_engine(name)}.to raise_error(
                                                   Delorean::BadCallError, err)
        end
      end

      # non-generated
      aggregate_failures "errors" do
        ['E5', 'a_func_p', 'E6', 'b_func_p'].in_groups_of(2) do |scr, fn|
          err = /Too many args to #{fn}/
          expect{Marty::ScriptSet.new.get_engine(scr)}.to raise_error(
                                             Delorean::BadCallError, err)
        end
      end
    end
    it "caching times" do
      ts = DateTime.now
      x=Benchmark.measure { 10000.times {
                            Gemini::FannieBup.a_func(ts,
                                                     1, 2)
                          }
      }
      y=Benchmark.measure { 10000.times {
                            Gemini::FannieBup.ca_func(ts, 
                                                     1, 2)
                          }
      }
      # x time should be 30x or more than y time
      expect(x.real / y.real).to be > 30
    end
  end
end
