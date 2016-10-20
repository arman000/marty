require 'spec_helper'
require 'job_helper'

describe Marty::Event do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    # transactional fixtures interfere with queueing jobs
    self.use_transactional_fixtures = false

    # Needed here because shutting transactional fixtures off
    # means we lose the globally set user
    Mcfly.whodunnit = UserHelpers.system_user

    Marty::Script.load_script_bodies(promise_bodies, Date.today)
    start_delayed_job
    Marty::Config["MARTY_EVENT_POLL_SECS"] = 1

    @time = Time.zone.now
    # add events
    [['testcl1',  123, @time, nil,            nil,     'AVM',     'a comment'],
     ['testcl1',  123, @time + 2.second, nil,nil,     'CRA',     'b comment'],
     ['testcl1',  123, @time + 4.seconds, nil,10000,     'PRICING', 'c comment'],
     ['testcl2', 123, @time, nil,             2, 'AVM',     'e comment'],
     ['testcl2', 123, @time + 1.second, nil,  4, 'CRA',     'f comment'],
    ].each do
      |klass, subjid, startdt, enddt, expire, op, comment|
      Marty::Event.create!(klass: klass,
                         subject_id: subjid,
                         start_dt: startdt,
                         end_dt: enddt,
                         expire_secs: expire,
                         comment: comment,
                         enum_event_operation: op)
    end


    engine = Marty::ScriptSet.new.get_engine(NAME_I)
    res = engine.background_eval("SLEEPER", {"secs" => 5}, ["a"],
                                {klass: "testcl3",
                                 id: 987,
                                 operation: 'PRICING'})
    res.force
    sleep 5
  end

  after(:all) do
    self.use_transactional_fixtures = true
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  it "Event tests" do
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq([])
    expect(Marty::Event.currently_running('testcl3', 987)).to eq([])

    expect(Marty::Event.last_event('testcl1', 123)).to include(
      {"klass"=>"testcl1",
       "subject_id"=>123,
       "enum_event_operation"=>"PRICING",
       "comment"=>"c comment", "expire_secs"=>10000})
    expect(Marty::Event.last_event('testcl2', 123)).to include(
      {"klass"=>"testcl2",
       "subject_id"=>123,
       "enum_event_operation"=>"CRA",
       "comment"=>"f comment",
       "expire_secs"=>4})
    expect(Marty::Event.last_event('testcl3', 987)).to include(
      {"klass"=>"testcl3",
        "subject_id"=>987,
        "enum_event_operation"=>"PRICING",
        "comment"=>nil,
        "expire_secs"=>nil})

    Timecop.freeze(@time+1.second)
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq(
      ['AVM', 'CRA'])

    Timecop.freeze(@time+3.seconds)
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq(
      ['CRA'])

    Timecop.freeze(@time+6.seconds)
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq(
      [])

    Timecop.return
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.op_is_running?('testcl1', 123, 'AVM')).to be_truthy
    Marty::Event.finish_event('testcl1', 123, 'AVM', 'wassup')
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).to eq(
      ['CRA', 'PRICING'])
    expect(Marty::Event.op_is_running?('testcl1', 123, 'AVM')).to be_falsey
    expect(Marty::Event.op_is_running?('testcl1', 123, 'CRA')).to be_truthy

    ev = Marty::Event.lookup_event('testcl1', 123, 'AVM')
    expect(ev.length).to eq(1)
    expect(ev.first).to include({"klass"=>"testcl1",
                                 "subject_id"=>123,
                                 "enum_event_operation"=>"AVM",
                                 "comment"=>"wassup",
                                 "expire_secs"=>nil})
    Marty::Event.update_comment(ev.first, "updated")
    ev = Marty::Event.lookup_event('testcl1', 123, 'AVM')
    expect(ev.first).to include({"comment"=>"updated"})
    expect(Marty::Event.compact_end_dt(ev.first)).to match(/\d\d:\d\d/)
    expect(Marty::Event.pretty_op(ev.first)).to eq('Avm')
    ev = Marty::Event.lookup_event('testcl1', 123, 'PRICING').first
    puts Marty::Event.pretty_op(ev)
  end
end
