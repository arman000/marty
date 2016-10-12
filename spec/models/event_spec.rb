require 'spec_helper'
require 'marty'
require 'delorean_lang'
require 'job_helper'

describe Marty::Event do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    start_delayed_job
  end

  after(:all) do
    self.use_transactional_fixtures = true
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  it "does" do
    Mcfly.whodunnit = UserHelpers.system_user
    time = Time.zone.now
    min1 = 1.minute
    min5 = 5.minutes
    min10 = 10.minutes
    # add events
    [['testclass', 123, time, nil, nil, 'AVM', 'a comment'],
     ['testclass', 123, time, time + 5.seconds, 'CRA', 'b comment'],
     ['testclass', 123, time, time + min10, nil, 'PRICING', 'c comment'],
     ['testclass2', 123, time, time + min1, nil, 'AVM', 'd comment'],
     ['testclass2', 123, time, nil, min5, 'AVM',  'e comment'],
     ['testclass2', 123, time, nil, min10, 'CRA', 'f comment'],
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
    Marty::Script.load_script_bodies(promise_bodies, Date.today)

    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    engine.background_eval("Y", {"p_title" => NAME_B}, ["result"])

    engine = Marty::ScriptSet.new.get_engine(NAME_I)
    engine.background_eval("SLEEPER", {"secs" => 10}, ["a"], {klass: "testclass3",
                                                              id: 987,
                                                              operation: 'PRICING'})
    expect (Marty::Event.currently_running('testclass', 123)).to eq([
    puts Marty::Event.currently_running('testclass2', 123)
    puts Marty::Event.currently_running('testclass3', 987)
    binding.pry
  end
end
=begin

test op_is_running?
test lookup_event
test finish_event
test last_event
test currently_running
=end
