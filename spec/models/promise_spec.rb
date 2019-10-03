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

  describe 'priority' do
    let(:user) { Marty::User.find_by(login: 'marty') }

    def run_prio_test(reverse: false, title:, runner:, job_cnt:)
      real_title = title + ' ' + reverse.to_s
      runner.call(reverse, real_title, job_cnt)
      base_p = nil
      timeout = 60
      # wait until base promise completes
      loop do
        base_p = Marty::Promise.find_by(title: real_title)
        break if p&.status || timeout == 0

        timeout -= 1
        sleep 1
      end
      [base_p, timeout]
    end

    it 'allows priority to be set' do
      ruby_runner = lambda do |reverse, title, job_cnt|
        Marty::Promises::Ruby::Create.call(
          module_name: 'Gemini::Helper',
          method_name: 'priority_tester',
          method_args: [reverse, job_cnt],
          params: { p_title: title, _user_id: user.id }
        )
      end

      engine = Marty::ScriptSet.new.get_engine(NAME_M)
      dl_runner = lambda do |reverse, title, job_cnt|
        result = engine.background_eval('Node',
                                        { 'p_title' => title,
                                          'job_cnt' => job_cnt,
                                          'reverse' => reverse }, ['result'])
      end

      results = []
      job_cnt = 40
      [['Ruby', ruby_runner],
       ['Delorean', dl_runner]].each do |type, runner|
        [true, false].each do |prio_order|
          base_pr, timeout = run_prio_test(runner: runner,
                                           title: 'Priority Base',
                                           reverse: prio_order,
                                           job_cnt: job_cnt)
          expect(base_pr.is_a?(Marty::Promise)).to be_truthy
          expect(base_pr.status).to be_truthy
          expect(timeout).to be < 45
          r = base_pr.result(true)['result']
          expect(r.count).to eq(job_cnt + 8)
          expect(r.to_set).to eq(Set.new(['5', '2']))

          logs = Marty::Log.all.order(:id).attributes
          Marty::Log.destroy_all
          results << [type, prio_order, logs]
        end
      end

      aggregate_failures do
        results.each do |type, dirflag, logs|
          err_str = "Type = #{type}, reverse=#{dirflag}"

          # look at the log in order to see how the jobs ran
          run_order = logs.map do |l|
            label = l.dig('details', 'label')
            label.starts_with?('Blocker') ? nil : label
          end.compact

          # get the priorities from the ordered list
          pris = run_order.map do |r|
            r.match(/pri=(\d+)/)[1].to_i
          end
          pc = pris.count

          #####################################################################
          # even though jobs start in order, variations in how they run (due to
          # os scheduling) are still possible. Also, 'run off' jobs usually run
          # out of order. Expect the log to be mostly in order (for any job,
          # most of the jobs that ran before it should be lower and most after
          # should be higher)
          #####################################################################

          # for each priority (job run) compute a score based on how many lower
          # priority jobs preceeded it and higher priority jobs followed it.
          comps = Array.new(pc) do |ind|
            lhs = ind - 1
            rhs = ind + 1
            lha = lhs > -1 ? pris[0..lhs] : []        # jobs that ran before
            rha = rhs <= pc - 1 ? pris[rhs..-1] : []  # jobs that ran after

            # score is an array of t/f ; t indicates correct ordering
            score = lha.map { |v| v < pris[ind] } + rha.map { |v| v > pris[ind] }
          end

          # count the trues for each job
          scores = comps.map { |a| a.count { |v| v } }

          avg_score = scores.sum.to_f / scores.count
          target = job_cnt * 0.75

          expect(avg_score).to be >= target
        end
      end
    end

    it 'inherits priority from parent' do
      ruby_runner = lambda do |priority = nil|
        title = "Ruby pri=#{priority}"
        params = { p_title: title,
                   _user_id: user.id,
                   p_priority: priority }.compact
        Marty::Promises::Ruby::Create.call(
          module_name: 'Gemini::Helper',
          method_name: 'priority_inh_tester',
          method_args: [title],
          params: params
        )
        title
      end
      engine = Marty::ScriptSet.new.get_engine(NAME_N)
      dl_runner = lambda do |priority = nil|
        title = "Delorean pri=#{priority}"
        result = engine.background_eval('Node',
                                        { 'p_title' => title,
                                          'title' => title,
                                          'p_priority' => priority }.compact,
                                        ['result'])
        title
      end
      results = []
      [ruby_runner,
       dl_runner].each do |runner|
        [nil, 123].each do |priority|
          title = runner.call(priority)
          timeout = 10
          r = nil
          loop do
            r = Marty::Promise.where("title like '#{title}%'").order(:title).
                  pluck(:title, :priority)
            break if r.count == 3 || timeout == 0

            timeout -= 1
            sleep 1
          end
          results << r
        end
      end
      # child1 should have same priority as parent, child2 should have 10
      exp = [[['Ruby pri=', 0],
              ['Ruby pri= child1', 0],
              ['Ruby pri= child2', 10]],
             [['Ruby pri=123', 123],
              ['Ruby pri=123 child1', 123],
              ['Ruby pri=123 child2', 10]],
             [['Delorean pri=', 0],
              ['Delorean pri= child1', 0],
              ['Delorean pri= child2', 10]],
             [['Delorean pri=123', 123],
              ['Delorean pri=123 child1', 123],
              ['Delorean pri=123 child2', 10]]]
      expect(results).to eq(exp)
    end
  end
end
