require 'job_helper'

describe Marty::JobController, slow: true, retry: 2 do
  before(:each) { @routes = Marty::Engine.routes }

  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    # transactional fixtures interfere with queueing jobs
    self.use_transactional_tests = false

    # Needed here because shutting transactional fixtures off
    # means we lose the globally set uesr
    Mcfly.whodunnit = system_user

    Marty::Script.load_script_bodies(promise_bodies, Time.zone.today)

    start_delayed_job
  end

  after(:each) do
    Marty::Promise.where('parent_id IS NULL').destroy_all
  end

  after(:all) do
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  def wait_for_jobs
    60.times do
      break unless Marty::Promise.where(result: {}).exists?

      sleep 1
    end
  end

  it 'should be able to evaluate in the foreground ' do
    engine = Marty::ScriptSet.new.get_engine(NAME_A)

    res = engine.evaluate('Y', 'd')
    expect(res).to eq([
                        { 'z' => 0.875, 'a' => { 'b' => { 'e' => 0.125 } } },
                        { 'z' => 0.875, 'a' => { 'b' => { 'e' => 1.125 } } },
                        { 'z' => 0.875, 'a' => { 'b' => { 'e' => 2.125 } } },
                      ])

    expect(Marty::Promise.where(start_dt: nil).count).to eq 0

    expect do
      res = engine.evaluate('Y', 'd', 's' => 1)
      # force res to be evaluated
      res.to_s
    end.to raise_error(RuntimeError)

    wait_for_jobs

    expect(Marty::Promise.where(start_dt: nil).count).to eq 0
  end

  it 'should be able to run long-running tasks in separate jobs' do
    engine = Marty::ScriptSet.new.get_engine(NAME_A)

    # NOTE: can't make this too small since the default
    # Delayed::Worker::sleep_delay is 5 seconds
    # However - delayed_job initializer config sets this to 1 for test
    slp = 5

    exp_res = { 'd' => [
      { 'z' => slp, 'a' => { 'b' => { 'e' => 1 - slp } } },
      { 'z' => slp, 'a' => { 'b' => { 'e' => 2 - slp } } },
      { 'z' => slp, 'a' => { 'b' => { 'e' => 3 - slp } } },
    ] }

    bench = Benchmark.measure do
      res = engine.evaluate('Y', 'f', 's' => slp)
      expect(res).to eq exp_res
    end

    # If "f" is evaluated in serial fashion, then the process would
    # take slp*3+ seconds.  Make sure that we had some parallel
    # behavior.
    expect(bench.real).to be_between(slp, slp * 2)
  end

  it 'should be able to run long-running tasks in separate jobs (2)' do
    engine = Marty::ScriptSet.new.get_engine(NAME_H)

    slp = 5 # hard-coded in script
    exp_res = { 'd' => [{ 'a' => 1 }, { 'a' => 4 }] }

    bench = Benchmark.measure do
      res = engine.background_eval('Y', {}, ['d'])

      expect(res).to eq exp_res
    end

    expect(bench.real).to be_between(slp, slp * 2)
  end

  xit 'should be to handle non-serializable errors' do
    # FIXME: this test is failing now.  Object not-serializable isn't
    # the issue.  This is caused by the 2nd promise not having been
    # started when it's forced.  Not sure this is really an issue.

    engine = Marty::ScriptSet.new.get_engine(NAME_C)
    res = engine.background_eval('Z', { 'p_title' => NAME_C }, ['result'])
    wait_for_jobs

    promise = Marty::Promise.find_by(title: NAME_C)

    get 'download', params: {
      job_id: promise.id,
    }

    expect(response.content_type).to eq 'application/json'
    expect(JSON.parse(response.body).keys.member?('error')).to be true
  end

  it 'promise proxies should be stored lazily (not expanded)' do
    engine = Marty::ScriptSet.new.get_engine(NAME_E)
    engine.background_eval('Z', { 'p_title' => NAME_E }, ['result'])
    wait_for_jobs

    promise = Marty::Promise.find_by(title: NAME_E)

    res = promise.result['result']

    expect(res.length).to eq 6

    # make sure that the contents are promise proxies (i.e. have
    # __force__) and therefore lazy.
    res.each { |r| expect(r.respond_to?(:__force__)).to be true }
  end

  it 'should not leave zombie promises when we have exceptions' do
    engine = Marty::ScriptSet.new.get_engine(NAME_D)
    engine.background_eval('Z', { 'p_title' => NAME_D }, ['result'])
    wait_for_jobs

    pl = Marty::Promise.all

    expect(pl.count).to eq 2

    pl.each do |p|
      expect(p.result['error']).not_to eq nil
      expect(p.end_dt).not_to eq nil
    end
  end

  it 'should pass p_title to promise create()' do
    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    res = engine.evaluate('Y', 'a', 'q' => 1)
    wait_for_jobs

    expect(res).to eq('b' => { 'e' => 0.125 })
    expect(Marty::Promise.all.map(&:title).sort).to eq(['aaa', 'bbb'])
  end

  it 'should be able to ask controller for job result' do
    title = 'BG RPC'
    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    engine.background_eval('Y', { 'p_title' => title }, ['d'])
    sleep 5

    promise = Marty::Promise.find_by(title: title)

    res = { 'd' => [
      { 'z' => 0.875, 'a' => { 'b' => { 'e' => 0.125 } } },
      { 'z' => 0.875, 'a' => { 'b' => { 'e' => 1.125 } } },
      { 'z' => 0.875, 'a' => { 'b' => { 'e' => 2.125 } } },
    ] }

    expect(promise.latest.result).to eq res

    get 'download', params: {
      format: :json,
      job_id: promise.id,
    }

    expect(JSON.parse response.body).to eq res
  end

  it 'should be able to get zip results' do
    title = 'BG ZIP'
    engine = Marty::ScriptSet.new.get_engine(NAME_B)
    engine.background_eval('Z',
                           {},
                           ['result', 'format', 'title'],
                          )
    sleep 5

    promise = Marty::Promise.find_by(title: NAME_B)

    expect(promise.result).to eq(
      'result' => [{ 'a' => 1, 'b' => 1 }, { 'a' => 2, 'b' => 4 }, { 'a' => 3, 'b' => 9 }],
      'format' => 'csv',
      'title' => 'PromiseB',
    )

    get 'download', params: {
      job_id: promise.id,
    }

    expect_csv = "a,b\r\n1,1\r\n2,4\r\n3,9\r\n"
    expect(response.body).to eq expect_csv
    expect(response.media_type).to eq 'text/csv'

    get 'download', params: {
      job_id: promise.parent_id,
    }

    expect(response.media_type).to eq 'application/zip'

    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      count = 0
      while (entry = io.get_next_entry)
        expect(entry.name).to match /PromiseB.*\.csv/
        expect(io.read).to eq expect_csv
        count += 1
      end
      expect(count).to eq 3
    end
  end

  it 'should be able to start promises on imported nodes' do
    engine = Marty::ScriptSet.new.get_engine(NAME_F)
    res = engine.evaluate('Z', 'result', {})
    expect(res).to eq 'x' * 10
  end

  it 'promises called from regular node calls should pass parent promise id' do
    engine = Marty::ScriptSet.new.get_engine(NAME_G)
    res = engine.evaluate('V', 'result', {})
    expect(res).to eq [123]
    p1 = Marty::Promise.find_by(title: NAME_G.to_s)
    p2 = Marty::Promise.find_by(title: "#{NAME_G}2")
    expect(p2.parent_id).to eq p1.id
  end
end
