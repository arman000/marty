require "spec_helper"

module Marty
entities = <<EOF
name
PLS
EOF
bud_cats = <<EOF
name
Conv Fixed 30
Conv Fixed 20
EOF

fannie_bup = <<EOF
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

script = <<EOF
A:
    pt        =?
    entity    =?
    note_rate =?
    e_id      =?
    bc_id     =?

    lookup   = Gemini::FannieBup.lookup(  pt, entity, note_rate)
    clookup  = Gemini::FannieBup.clookup( pt, entity, note_rate)

    lookupn  = Gemini::FannieBup.lookupn( pt, entity, note_rate)

    clookupn = Gemini::FannieBup.clookupn(pt, entity, note_rate)

    a_func = Gemini::FannieBup.a_func('infinity', e_id, bc_id)
    b_func = Gemini::FannieBup.b_func('infinity', e_id, bc_id, 12)
EOF
errscript = <<EOF
Err:
    pt        =?
    entity    =?
    note_rate =?
    result = Gemini::FannieBup.%s(pt, entity, note_rate, 1)
EOF
errscript2 = <<EOF
Err:
    pt    =?
    e_id  =?
    bc_id =?
    result = Gemini::FannieBup.%s(pt, e_id, bc_id, nil)
EOF
errscript3 = <<EOF
Err:
    pt    =?
    e_id  =?
    bc_id =?
    mm    =?
    result = Gemini::FannieBup.%s(pt, e_id, bc_id, mm, {})
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

    Marty::Script.load_script_bodies({ 'E5' => (errscript2 % 'a_func_p') }, dt)
    Marty::Script.load_script_bodies({ 'E6' => (errscript3 % 'b_func_p') }, dt)

    @engine = Marty::ScriptSet.new.get_engine("AA")
  end
  after(:all) do
    restore_clean_db(@clean_file)
    Marty::ScriptSet.clear_cache
  end
  let(:params) do
    { "pt" => 'infinity',
                 "entity"    => Gemini::Entity.all.first,
                 "note_rate" => 2.875 }
  end
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
    # a1 will be AR Relations
    # b1 will be OpenStructs because the b fns return #first
    e_id = Gemini::Entity.where(name: "PLS").first.id
    bc_id = Gemini::BudCategory.where(name: "Conv Fixed 20").first.id
    p = { "e_id" => e_id, "bc_id" => bc_id }
    a1 = @engine.evaluate("A", "a_func", p)
    b1 = @engine.evaluate("A", "b_func", p)

    # all return relations
    expect(ActiveRecord::Relation === a1).to be_truthy
    expect(ActiveRecord::Base === a1.first).to be_truthy

    expect(a1.to_a.count).to eq(2)

    # a1 lookup did not include extra attrs
    expect(a1.first.attributes.keys.to_set).to eq(Set["id", "buy_up", "buy_down"])

    # a1 is AR but still missing the FK entity_id so will raise
    expect { a1.first.entity }.to raise_error(/missing attribute: entity_id/)

    expect(b1.class).to eq(OpenStruct)

    # make sure b1 has correct keys
    expect(b1.to_h.keys.to_set).to eq(Set[:buy_up, :buy_down])
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

        expect do
          Marty::ScriptSet.new.get_engine(name)
        end.to raise_error(Delorean::BadCallError, err)
      end
    end
  end

  it "private methods can't be called by delorean (2)" do
    # non-generated
    aggregate_failures "errors" do
      ['E5', 'a_func_p', 'E6', 'b_func_p'].in_groups_of(2) do |scr, fn|
        err = /Too many args to #{fn}/
        expect { Marty::ScriptSet.new.get_engine(scr) }.to raise_error(
          Delorean::BadCallError, err)
      end
    end
  end

  it "caching times" do
    ts = DateTime.now
    x = Benchmark.measure do
        10000.times do
                          Gemini::FannieBup.a_func(ts,
                                                   1, 2)
        end
    end
    y = Benchmark.measure do
        10000.times do
                          Gemini::FannieBup.ca_func(ts,
                                                    1, 2)
        end
    end
    # x time should be 30x or more than y time
    expect(x.real / y.real).to be > 30
  end
end
end
