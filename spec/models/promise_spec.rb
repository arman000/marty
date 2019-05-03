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
    Mcfly.whodunnit = system_user

    Marty::Script.load_script_bodies(promise_bodies, Date.today)

    start_delayed_job
  end

  before(:each) do
    @time = DateTime.now
    expect(Marty::Promise.count).to eq(0)
    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    engine.background_eval('Y', { 'p_title' => NAME_A }, ['d'])
    sleep 5
    Marty::Promise.cleanup
    expect(Marty::Promise.count).to eq(10)
  end

  after(:each) do
    Marty::Log.delete_all
    Marty::Promise.where('parent_id IS NULL').destroy_all
    Timecop.return
  end

  after(:all) do
    restore_clean_db(@clean_file)
    stop_delayed_job
  end

  it 'should retain jobs that were run less than 4 hours ago' do
    Timecop.freeze(@time + 4.hours)
    Marty::Promise.cleanup
    expect(Marty::Promise.count).to eq(10)
  end

  it 'should cleanup jobs that are older than 4 hours' do
    Timecop.freeze(@time + 4.hours + 1.minute)
    Marty::Promise.cleanup
    expect(Marty::Promise.count).to eq(0)
  end

  it 'should allow cleanup of all jobs when forced by admin' do
    Timecop.freeze(@time + 4.hours)
    Marty::Promise.cleanup(true)
    expect(Marty::Promise.count).to eq(0)
  end

  it 'should provide a live search scope for filtering by user or role' do
    expect(Marty::VwPromise.live_search('XXX').size).to eq(0)
    expect(Marty::VwPromise.live_search('marty').size).to eq(10)
    expect(Marty::VwPromise.live_search('Admin').size).to eq(10)
  end

  describe 'delorean' do
    it 'processes result' do
      expect(Marty::Promise.where(title: 'PromiseB').exists?).to be false

      engine = Marty::ScriptSet.new.get_engine(NAME_B)
      engine.background_eval(
        'Y',
        {
          'p_title' => NAME_B,
          'p_hook' => Gemini::PromiseHook::TestHook
        },
        ['result']
      )

      promise = Marty::Promise.find_by(title: 'PromiseB')
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)
      promise.reload

      expected = [{ 'a' => 1, 'b' => 1 }, { 'a' => 2, 'b' => 4 }, { 'a' => 3, 'b' => 9 }]
      expect(promise.status).to be true
      expect(promise.promise_type).to eq 'delorean'
      expect(promise.result['error']).to be nil
      expect(promise.result['result']).to eq expected

      sleep 0.1 # Wait while hooks are executed after Promise was updated
      log = Marty::Log.find_by(message_type: 'TestHook')
      expect(log.message).to eq 'was called'
    end

    it 'fails on exception' do
      expect(Marty::Promise.where(title: 'PromiseJ').exists?).to be false

      engine = Marty::ScriptSet.new.get_engine(NAME_J)
      engine.background_eval('FAILER', { 'p_title' => NAME_J }, ['a'])

      promise = Marty::Promise.find_by(title: 'PromiseJ')
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)
      promise.reload

      expect(promise.status).to be false
      expect(promise.promise_type).to eq 'delorean'
      expect(promise.result['error']).to eq 'I had an error'
      expect(promise.job_id).to be_present
    end
  end

  describe 'ruby' do
    let(:user) { Marty::User.find_by(login: 'marty') }

    it 'processes result with regular attrs' do
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::BudCategory',
        method_name: 'create_from_promise_regular_attrs',
        method_args: ['test name', 1],
        params: {
          p_title: 'test_title',
          _user_id: user.id,
          p_hook: Gemini::PromiseHook::TestHook
        }
      )

      promise = Marty::Promise.where(promise_type: 'ruby').last
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)

      promise.reload

      bud_category = Gemini::BudCategory.order(:id).last
      expect(bud_category.name).to eq 'test name'

      sleep 0.1 # Wait while hooks are executed after Promise was updated
      log = Marty::Log.find_by(message_type: 'TestHook')

      expect(promise.status).to be true
      expect(promise.promise_type).to eq 'ruby'
      expect(promise.result['result']).to eq bud_category.id
      expect(promise.job_id).to be_present
      expect(log.message).to eq 'was called'
    end

    it 'processes result with keyword attrs' do
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::BudCategory',
        method_name: 'create_from_promise_keyword_attrs',
        method_args: [group_id: 1, name: 'test name 2'],
        params: {
          _user_id: user.id,
        }
      )

      promise = Marty::Promise.where(promise_type: 'ruby').last
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)

      promise.reload

      bud_category = Gemini::BudCategory.order(:id).last
      expect(bud_category.name).to eq 'test name 2'

      expect(promise.status).to be true
      expect(promise.promise_type).to eq 'ruby'
      expect(promise.result['result']).to eq bud_category.id
    end

    it 'processes result with mixed attrs' do
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::BudCategory',
        method_name: 'create_from_promise_mixed_attrs',
        method_args: ['test name 3', { group_id: 1 }],
        params: {
          _user_id: user.id,
        }
      )

      promise = Marty::Promise.where(promise_type: 'ruby').last
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)

      promise.reload

      bud_category = Gemini::BudCategory.order(:id).last
      expect(bud_category.name).to eq 'test name 3'

      expect(promise.status).to be true
      expect(promise.promise_type).to eq 'ruby'
      expect(promise.result['result']).to eq bud_category.id
    end

    it 'fails on exception' do
      Marty::Promises::Ruby::Create.call(
        module_name: 'Gemini::BudCategory',
        method_name: 'create_from_promise_error',
        method_args: [],
        params: {
          _user_id: user.id,
        }
      )

      promise = Marty::Promise.where(promise_type: 'ruby').last
      promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)

      promise.reload

      expect(promise.status).to be false
      expect(promise.promise_type).to eq 'ruby'
      expect(promise.result['error']).to eq 'Something went wrong'
      expect(promise.result['backtrace']).to_not be_empty
    end
  end
end
