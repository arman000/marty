require 'spec_helper'
require 'job_helper'

describe Marty::Promise, slow: true do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    # transactional fixtures interfere with queueing jobs
    self.use_transactional_tests = false

    # Needed here because shutting transactional fixtures off
    # means we lose the globally set user
    Mcfly.whodunnit = UserHelpers.system_user

    Marty::Script.load_script_bodies(promise_bodies, Date.today)

    start_delayed_job
  end

  before(:each) do
    @time = DateTime.now
    expect(Marty::Promise.unscoped.count).to eq(0)
    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    engine.background_eval("Y", {"p_title" => NAME_A}, ["d"])
    sleep 5
    Marty::Promise.cleanup
    expect(Marty::Promise.unscoped.count).to eq(10)
  end

  after(:each) do
    Marty::Promise.where('parent_id IS NULL').destroy_all
    Timecop.return
  end

  after(:all) do
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  it "should retain jobs that were run less than 4 hours ago" do
    Timecop.freeze(@time + 4.hours)
    Marty::Promise.cleanup
    expect(Marty::Promise.unscoped.count).to eq(10)
  end

  it "should cleanup jobs that are older than 4 hours" do
    Timecop.freeze(@time + 4.hours + 1.minute)
    Marty::Promise.cleanup
    expect(Marty::Promise.unscoped.count).to eq(0)
  end

  it "should allow cleanup of all jobs when forced by admin" do
    Timecop.freeze(@time + 4.hours)
    Marty::Promise.cleanup(true)
    expect(Marty::Promise.unscoped.count).to eq(0)
  end

  it "should provide a live search scope for filtering by user or role" do
    expect(Marty::Promise.live_search('XXX').size).to eq(0)
    expect(Marty::Promise.live_search('marty').size).to eq(10)
    expect(Marty::Promise.live_search('Admin').size).to eq(10)
  end
end
