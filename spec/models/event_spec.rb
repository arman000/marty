require 'spec_helper'
require 'job_helper'

describe Marty::Event do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    @save_file = "/tmp/save_#{Process.pid}.psql"
    save_clean_db(@clean_file)

    # transactional fixtures interfere with queueing jobs
    self.use_transactional_tests = false

    # Needed here because shutting transactional fixtures off
    # means we lose the globally set user
    Mcfly.whodunnit = UserHelpers.system_user

    Marty::Script.load_script_bodies(promise_bodies, Date.today)
    start_delayed_job
    Marty::Config["MARTY_EVENT_POLL_SECS"] = 1

    @time = Time.zone.now
    @date_string = @time.strftime('%Y-%m-%d')
    @old_start = '1970-01-01 08:00:00'
    @old_end = '1970-01-01 09:00:00'
    # add events
    [['testcl1',  123, @time, nil,            nil,     'AVM',     'a comment',
      nil],
     ['testcl1',  123, @time + 2.second, nil,nil,     'CRA',     'b comment',
      nil],
     ['testcl1',  123, @time + 4.seconds, nil,10000,     'PRICING', 'c comment',
      nil],
     ['testcl1',  234, @time - 5.seconds, @time, nil,    'PRICING', 'c comment',
      false],
     ['testcl2', 123, @time, nil,             2, 'AVM',     'e comment', nil],
     ['testcl2', 123, @time + 1.second, nil,  4, 'CRA',     'f comment', nil],
     ['testcl2', 123, Time.zone.parse(@old_start),
      Time.zone.parse(@old_end), nil, 'PRICING', 'old event', 0],
    ].each do
      |klass, subjid, startdt, enddt, expire, op, comment, error|
      Marty::Event.create!(klass: klass,
                           subject_id: subjid,
                           start_dt: startdt,
                           end_dt: enddt,
                           expire_secs: expire,
                           comment: comment,
                           enum_event_operation: op,
                           error: error)
    end


    engine = Marty::ScriptSet.new.get_engine(NAME_I)
    res = engine.background_eval("SLEEPER", {"secs" => 5}, ["a"],
                                 {klass: "testcl3",
                                  id: 987,
                                  operation: 'PRICING'})
    res.force
    engine = Marty::ScriptSet.new.get_engine(NAME_J)
    res = engine.background_eval("FAILER", {"dummy" => "dummy"}, ["a"],
                                 {klass: "testcl3",
                                  id: 654,
                                  operation: 'PRICING'})
    res.force rescue nil
    sleep 5
    save_clean_db(@save_file)
  end

  after(:all) do
    self.use_transactional_tests = true
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  before(:each) do
    restore_clean_db(@save_file, false)
    Marty::Event.clear_cache
  end


  it "reports currently running" do
    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq([])
    expect(Marty::Event.currently_running('testcl3', 987)).to eq([])
    expect(Marty::Event.last_event('testcl1', 123)).
      to include(
           {"klass"=>"testcl1",
            "subject_id"=>123,
            "enum_event_operation"=>"PRICING",
            "comment"=>"c comment", "expire_secs"=>10000})
    expect(Marty::Event.last_event('testcl2', 123)).
      to include(
           {"klass"=>"testcl2",
            "subject_id"=>123,
            "enum_event_operation"=>"PRICING",
            "comment"=>"old event"})
    expect(Marty::Event.last_event('testcl3', 987)).
      to include(
           {"klass"=>"testcl3",
            "subject_id"=>987,
            "enum_event_operation"=>"PRICING",
            "comment"=>nil,
            "expire_secs"=>nil})

    Timecop.freeze(@time+1.second)
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq(['AVM', 'CRA'])

    Timecop.freeze(@time+3.seconds)
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq(['CRA'])

    Timecop.freeze(@time+6.seconds)
    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.currently_running('testcl2', 123)).to eq([])
    Timecop.return

  end

  it "misc API tests" do
    ev1 = Marty::Event.where(klass: 'testcl3', subject_id: 987).first
    ev2 = Marty::Event.where(klass: 'testcl3', subject_id: 654).first
    af = Marty::Event.all_finished
    ev3 = Marty::Event.where(klass: 'testcl3', subject_id: 987).first
    ev4 = Marty::Event.where(klass: 'testcl3', subject_id: 654).first

    # ev1/ev2 should have null start/end
    # ev3/ev4 should have start/end populated from promise and error status
    expect(ev1.start_dt).to be_nil
    expect(ev1.end_dt).to be_nil
    expect(ev1.error).to be_falsey
    expect(ev2.start_dt).to be_nil
    expect(ev2.end_dt).to be_nil
    expect(ev2.error).to be_falsey

    expect(ev3.start_dt).not_to be_nil
    expect(ev3.end_dt).not_to be_nil
    expect(ev3.error).to be_falsey
    expect(ev4.start_dt).not_to be_nil
    expect(ev4.end_dt).not_to be_nil
    expect(ev4.error).to be_truthy

    expect(af.count).to eq(3)
    expect(af).to include(['testcl3', 987])
    expect(af).to include(['testcl1', 234])
    expect(af[['testcl3', 987]]).to include('PRICING')
    expect(af[['testcl3', 987]]['PRICING']).to start_with(@date_string)
    expect(af[['testcl1', 234]]).to include('PRICING')
    expect(af[['testcl1', 234]]['PRICING']).to start_with(@date_string)

    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['AVM', 'CRA', 'PRICING'])
    expect(Marty::Event.op_is_running?('testcl1', 123, 'AVM')).to be_truthy
    Marty::Event.finish_event('testcl1', 123, 'AVM', false, 'wassup')
    Marty::Event.clear_cache
    expect(Marty::Event.currently_running('testcl1', 123)).
      to eq(['CRA', 'PRICING'])
    expect(Marty::Event.currently_running_multi('testcl1', [123])).
      to eq({123 => ['CRA', 'PRICING']})

    expect(Marty::Event.op_is_running?('testcl1', 123, 'AVM')).to be_falsey
    expect(Marty::Event.op_is_running?('testcl1', 123, 'CRA')).to be_truthy

    ev = Marty::Event.lookup_event('testcl1', 123, 'AVM')
    expect(ev.length).to eq(1)
    expect(ev.first).to include({"klass"=>"testcl1",
                                 "subject_id"=>123,
                                 "enum_event_operation"=>"AVM",
                                 "comment"=>"wassup",
                                 "expire_secs"=>nil,
                                 "error"=>'f'})
    Marty::Event.update_comment(ev.first, "updated")
    ev = Marty::Event.lookup_event('testcl1', 123, 'AVM')
    expect(ev.first).to include({"comment"=>"updated"})
    expect(Marty::Event.compact_end_dt(ev.first)).to match(/\d\d:\d\d/)
    expect(Marty::Event.pretty_op(ev.first)).to eq('Avm')
    ev = Marty::Event.lookup_event('testcl1', 123, 'PRICING').first
    expect(Marty::Event.pretty_op(ev)).to eq('Pricing')
    evs = Marty::Event.last_event_multi('testcl1', [123, 234])
    expect(evs[123]).to include({"klass"=>"testcl1",
                                 "subject_id"=>123,
                                 "enum_event_operation"=>"CRA",
                                 "comment"=>"b comment",
                                 "expire_secs"=>nil,
                                 "error"=>nil})
    expect(evs[234]).to include({"klass"=>"testcl1",
                                 "subject_id"=>234,
                                 "enum_event_operation"=>"PRICING",
                                 "comment"=>"c comment",
                                 "expire_secs"=>nil,
                                 "error"=>"f"})

    af = Marty::Event.all_finished
    expect(af.count).to eq(4)
    expect(af[['testcl3', 987]]).to include('PRICING')
    expect(af[['testcl1', 123]]).to include('AVM')
    expect(af[['testcl1', 123]]['AVM']).to start_with(@date_string)
  end

  it "raises on error" do
    expect {Marty::Event.create_event('testcl', 1234, 'AVM', Time.zone.now, 600,
                                      "the comment") }.not_to raise_error

    expect {Marty::Event.create_event('testcl', 1234, 'AVM', Time.zone.now, 600,
                                      "the comment") }.
      to raise_error(%r!AVM is already running for testcl/1234!)
    expect {Marty::Event.create_event('testcl', 2345, 'AVM', Time.zone.now, 600,
                                      "the comment") }.not_to raise_error
    expect {Marty::Event.finish_event('testcl', 1234, 'AVM', false,
                                      "new comment") }.
      not_to raise_error
    expect {Marty::Event.finish_event('testcl', 1234, 'AVM', false,
                                      "new comment") }.
      to raise_error(%r!event testcl/1234/AVM not found!)
    expect {Marty::Event.finish_event('testcl', 2345, 'AVM', false, 'foobar') }.
      not_to raise_error
    expect {Marty::Event.finish_event('testcl', 2345, 'AVM', false, 'foobar') }.
      to raise_error(%r!event testcl/2345/AVM not found!)
    expect {Marty::Event.finish_event('testcl', 2345, 'AVM', nil, 'foobar') }.
      to raise_error(/error must be true or false/)
    expect {Marty::Event.create_event('testcl', 1234, 'AMV', Time.zone.now, 600,
                                      "the comment") }.
      to raise_error(%r!PG::.*invalid input value for enum.*"AMV"!)
    Marty::Event.clear_cache
    af = Marty::Event.all_finished
    expect(af.count).to eq(5)
    expect(af).to include(['testcl', 1234])
    expect(af).to include(['testcl', 2345])
    expect(af[['testcl', 1234]]).to include('AVM')
    expect(af[['testcl', 2345]]).to include('AVM')
    expect(af[['testcl', 1234]]['AVM']).to start_with(@date_string)
    expect(af[['testcl', 2345]]['AVM']).to start_with(@date_string)
  end

  it "truncates long comment" do
    long_comment = "comment string abcdefg"*100
    long_comment_truncated = long_comment.truncate(255)
    Marty::Event.create_event('testcl', 123, 'PRICING', Time.zone.now, 600,
                              long_comment)
    Marty::Event.create!(klass: 'testcl',
                         subject_id: 456,
                         enum_event_operation: 'CRA',
                         start_dt: Time.zone.now,
                         expire_secs: 600,
                         comment: long_comment)

    Marty::Event.create_event('testcl', 789, 'AVM', Time.zone.now, 600,
                              "comment")
    Marty::Event.finish_event('testcl', 789, 'AVM', false, long_comment)

    e1 = Marty::Event.lookup_event('testcl', 123, 'PRICING').first
    e2 = Marty::Event.lookup_event('testcl', 456, 'CRA').first
    e3 = Marty::Event.lookup_event('testcl', 789, 'AVM').first

    expect(e1["comment"]).to eq(long_comment_truncated)
    expect(e2["comment"]).to eq(long_comment_truncated)
    expect(e3["comment"]).to eq(long_comment_truncated)

  end
end
