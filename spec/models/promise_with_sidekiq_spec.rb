require 'spec_helper'
require 'job_helper'
# require 'sidekiq/testing'

describe Marty::Promise, slow: true, retry: 1 do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    # transactional fixtures interfere with queueing jobs
    self.use_transactional_tests = false

    # Needed here because shutting transactional fixtures off
    # means we lose the globally set user
    Mcfly.whodunnit = system_user

    Marty::Script.load_script_bodies(promise_bodies, Time.zone.today)

    start_sidekiq
  end

  before(:each) do
    Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = true
    Sidekiq::Queue.all.each(&:clear)
    ActiveRecord::Base.connection.reconnect!
    @time = DateTime.now
    expect(Marty::Promise.count).to eq(0)
    engine = Marty::ScriptSet.new.get_engine(NAME_A)
    engine.background_eval('Y', { 'p_title' => NAME_A }, ['d'])
    sleep 5
    Marty::Promise.cleanup
    expect(Marty::Promise.count).to eq(10)
  end

  after(:each) do
    Marty::Config['USE_SIDEKIQ_WITH_PROMISES'] = false
    ActiveRecord::Base.connection.reconnect!
    Marty::Log.delete_all
    Marty::Promise.where('parent_id IS NULL').destroy_all
    Timecop.return
  end

  after(:all) do
    stop_sidekiq
    restore_clean_db(@clean_file)
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
    it 'timeout test' do
      engine = Marty::ScriptSet.new.get_engine(NAME_O)
      timeout = 2

      [0, 1, 3, 4].each do |seconds_to_sleep|
        st = Time.zone.now
        x = engine.background_eval('Node', { p_timeout: timeout }, 'call_sleep')
        error = nil

        sleep seconds_to_sleep

        begin
          y = "result returned: #{x}"
        rescue StandardError => e
          error = "error raised: #{e.message}"
        end

        # If we check before timeout, ruby should wait until promise is timed out
        # so that total time would be just above the timeout time.
        # If sleep is longer than timeout, total time would be slightly above
        # the sleep time
        runtime = Time.zone.now - st
        expected_time = [seconds_to_sleep, timeout].max

        expect(runtime > expected_time).to be true
        expect(runtime < expected_time + 0.5).to be true
        expect(error).to be_present
        expect(error).to include('Triggered by Marty::WorkerTimeout')
      end
    end

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
      expect(promise.run_by).to be_present
      expect(promise.result['result']).to eq expected

      sleep 0.2 # Wait while hooks are executed after Promise was updated
      log = Marty::Log.find_by(message_type: 'TestHook')
      expect(log.message).to eq 'was called'
    end

    it 'can cancel jobs' do
      Marty::Promise.delete_all

      run_ruby_job = lambda do |title1, title2|
        title = title1 + ' ' + title2
        Marty::Promises::Ruby::Create.call(
          module_name: 'Gemini::Helper',
          method_name: 'promise_test',
          method_args: [title2],
          params: {
            p_title: title,
            _user_id: 1,
          }
        )
      end

      engine = Marty::ScriptSet.new.get_engine(NAME_L)

      run_delorean_job = lambda do |title1, title2|
        engine.background_eval('Node', { 'p_title' => title1 + ' ' + title2,
                                         'job_title' => title2 }, ['base_attr'])
      end

      aggregate_failures do
        Sidekiq::Queue.all.each(&:clear)
        stop_sidekiq
        sleep 2
        start_sidekiq
        sleep 2

        [
          ['Ruby', run_ruby_job],
          ['PromiseL', run_delorean_job]
        ].each do |title1, runner|
          # first run with no cancel.  make sure the test parts work as expected
          title2 = 'first run'

          x = runner.call(title1, title2)

          base_p = nil
          timeout = 60

          # wait until base promise completes
          loop do
            base_p = Marty::Promise.find_by("title like '#{title1}%'")
            break if p&.status || timeout == 0

            timeout -= 1
            sleep 1
          end

          expect(base_p.is_a?(Marty::Promise)).to be_truthy
          expect(base_p.status).to be_truthy
          expect(timeout).to be < 55

          # count promises that ran
          ps = Marty::Promise.where("title like '#{title2} %' or "\
                                    "title = '#{title1} #{title2}'").
                 pluck(:id, :title, :end_dt, :status, :result)

          # this check could fail on rare occasion due to the fact that
          # delayed jobs sometimes run twice
          expect(ps.count).to eq(13)

          # check status
          expect(ps.all? { |p| p[4] }).to be_truthy

          # check the names
          exp_pnames = [
            'first run 1', 'first run 1 1', 'first run 1 2', 'first run 1 3',
            'first run 2', 'first run 2 1', 'first run 2 2', 'first run 2 3',
            'first run 3', 'first run 3 1', 'first run 3 2', 'first run 3 3'
          ]

          expect(ps.map { |p| p[1] }.reject { |s| s.starts_with?(title1) }.sort).
            to eq(exp_pnames)

          # make sure the log was written by the leaf jobs. (uniq because
          # rarely jobs run twice due to race condition -- see promise.rb:126)
          exp_log = ['first run 1 1', 'first run 1 2', 'first run 1 3',
                     'first run 2 1', 'first run 2 2', 'first run 2 3',
                     'first run 3 1', 'first run 3 2', 'first run 3 3']
          logs = Marty::Log.all.pluck(:details).map { |d| d['label'] }.sort.uniq
          expect(logs).to eq(exp_log)

          Marty::Promise.where("title like '#{title2}%'").destroy_all
          Marty::Log.where("details->>'label' like '#{title2}%'").destroy_all

          # run with early cancel
          cancel_with_checks(runner, title1, 'cancel_check_1 2nd run', '1', ps.count,
                             exp_log.count)

          # run with later cancel
          cancel_with_checks(runner, title1, 'cancel_check_2 3rd run', '1 1', ps.count,
                             exp_log.count)

          # some workers may die because we deleted the promises,
          # so restart them
          stop_sidekiq
          start_sidekiq
        end
      end
    end

    def cancel_with_checks(runner, title1, title2, cancel_name, cnt1, cnt2)
      testinfo = "#{title1} #{title2}"
      runner.call(title1, title2)

      # wait for indicated job and cancel
      timeout = 30
      title_where = "title = '#{title2} #{cancel_name}'"
      until timeout == 0 || (p = Marty::Promise.find_by(title_where))
        sleep 1
        timeout -= 1
      end

      sleep 0.5

      expect(p).to be_a(Marty::Promise), testinfo

      Marty::Promises::Cancel.call(p.id)

      # count the logs that were generated, should be less
      l = Marty::Log.where("details->>'label' like '#{title2}%'").uniq
      expect(l.count).to be < cnt2, testinfo

      ps = Marty::Promise.where("title like '#{title2} %' or "\
                                    "title = '#{title1} #{title2}'").
                 pluck(:id, :title, :end_dt, :status, :result)
      # cancel should have stopped creation of promises
      expect(ps.count).to be < cnt1, testinfo

      # make sure all the promises have an error=Cancelled in result
      errors = ps.map(&:last).map { |h| h['error'] }.to_set
      expect(errors).to eq(['Cancelled'].to_set), testinfo
      Marty::Promise.where("title like '#{title2}%'").destroy_all
      Marty::Log.where("details->>'label' like '#{title2}%'").destroy_all
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
      expect(promise.run_by).to be_present
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
      expect(promise.run_by).to be_present
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
      expect(promise.run_by).to be_present
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
      expect(promise.run_by).to be_present
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
      expect(promise.run_by).to be_present
      expect(promise.result['error']).to eq 'Something went wrong'
      expect(promise.result['backtrace']).to_not be_empty
    end

    describe 'without DJs' do
      before do
        stop_sidekiq
      end

      after do
        start_sidekiq
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
        # Simulate exception outside of the job
        expect(promise).to receive(:work_off_job).once.and_raise 'Test exception'

        promise.wait_for_result(Marty::Promise::DEFAULT_PROMISE_TIMEOUT)
        promise.reload

        expect(promise.status).to be false
        expect(promise.promise_type).to eq 'ruby'
        expect(promise.result['error']).to eq 'Test exception'
        expect(promise.result['backtrace']).to_not be_empty
      end
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

    def test_priorities(runner:)
      # Create 10 regular priority promises, 10 low priority promies
      # and 10 regular priority again.
      # Most of regular priority promises should start before the low priority ones

      10.times do |i|
        runner.call("Regular priority ##{i}", 0)
      end

      10.times do |i|
        runner.call("Low priority ##{i}", 1)
      end

      10.times do |i|
        runner.call("Regular priority 2nd run ##{i}", 0)
      end

      last_promise = Marty::Promise.find_by(title: 'Low priority #9')

      60.times do
        break if last_promise.reload.status

        sleep 1
      end

      regular_priority_promises = Marty::Promise.where(
        "title ILIKE '%Regular priority 2nd run %'"
      )

      low_priority_promises = Marty::Promise.where(
        "title ILIKE '%Low priority%'"
      )

      all_promises = regular_priority_promises + low_priority_promises
      sorted = all_promises.sort_by(&:start_dt)

      top_10_priorities = sorted.first(10).map(&:priority)
      default_priority_count = top_10_priorities.count { |p| p == 0 }

      # More than 80% of regular promises should have been started
      # before the low priority ones
      expect(default_priority_count >= 8).to be true
    end

    it 'allows priority to be set with ruby promises' do
      runner = lambda do |title, priority|
        Marty::Promises::Ruby::Create.call(
          module_name: 'Gemini::Helper',
          method_name: 'priority_tester2',
          method_args: [],
          params: {
            p_title: title,
            _user_id: user.id,
            p_priority: priority
          }
        )
      end

      test_priorities(runner: runner)
    end

    it 'allows priority to be set with delorean promises' do
      engine = Marty::ScriptSet.new.get_engine(NAME_M)

      runner = lambda do |title, priority|
        result = engine.background_eval(
          'Node2',
          { 'p_title' => title, 'p_priority' => priority },
          ['result']
        )
      end

      test_priorities(runner: runner)
    end

    xit 'allows priority to be set' do
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
