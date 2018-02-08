require 'spec_helper'
require 'job_helper'

describe Marty::Delayed::Scheduler do

  before(:all) do
    Marty::Config['SCHEDULER_HEARTBEAT'] = 0
    Marty::Script.load_scripts(nil, Date.today)
    self.use_transactional_tests = false
    scheduler_clean_up
  end

  after(:all) do
    self.use_transactional_tests = true
    Marty::Config['SCHEDULER_HEARTBEAT'] = 60
  end

  after(:each) do
    scheduler_clean_up
  end

  def scheduler_clean_up
    Marty::SchedulerLife.delete_all
    Marty::ScheduledJob.delete_all
    Marty::Promise.delete_all
    Timecop.freeze
  end

  def mimic_scheduler
    Marty::SchedulerLife.delete_all
    Delayed::Job.delete_all
    Marty::SchedulerLife.create!

    # mimic scheduler by forcing timeout
    # on scheduler loop and working off
    # scheduled any delayed jobs
    Timeout.timeout(1) {
      Marty::Delayed::Scheduler.new.perform
    } rescue Timeout.timeout(30) {
               Delayed::Worker.new.work_off
             }
  end

  def with_delayed_job n=1, sleep_time=0
    config = Marty::Config['SCHEDULER_DEPLOY_ON_INITIALIZATION']
    Marty::Config['SCHEDULER_DEPLOY_ON_INITIALIZATION'] = true
    start_delayed_job(n=n, sleep_time=sleep_time)
    yield if block_given?
    stop_delayed_job
    Marty::Config['SCHEDULER_DEPLOY_ON_INITIALIZATION'] = config
  end

  def start_stop_delayed_job
    with_delayed_job
  end

  describe 'initialization behavior' do
    before(:all) do
      Delayed::Worker.delay_jobs = false
      Timecop.freeze
    end

    after(:all) do
      Delayed::Worker.delay_jobs = true
      Timecop.return
    end

    after(:each) do
      scheduler_clean_up
    end

    it 'creates only one scheduler entry during initialization' do
      expect(Marty::SchedulerLife.all.count).to eq(0)
      start_stop_delayed_job
      expect(Marty::SchedulerLife.all.count).to eq(1)
    end

    it 'will create a new scheduler life when another expires' do
      start_stop_delayed_job
      pid = Marty::SchedulerLife.first.pid
      Timecop.travel(2.day.from_now)
      start_stop_delayed_job
      expect(pid).to_not eq(Marty::SchedulerLife.first.pid)
    end
  end

  describe 'job creation and execution' do
    before(:all) do
      stop_delayed_job
      Timecop.freeze
    end

    after(:all) do
      Timecop.return
    end

    after(:each) do
      scheduler_clean_up
    end

    it 'one off jobs with multiple attempts can perform polling jobs' do
      job = Marty::ScheduledJob.create!(
        second: '0',
        minute: '*',
        max_attempts: 4,
        delorean_descriptor: {
          'script' => 'ScriptReport',
          'node'   => 'PrettyScript',
          'attrs'   => 'script_id',
        },
        params: {
          'script_id' => nil
        }
      )

      expect(job.last_completed_dt).to eq(nil)
      expect(job.processed).to eq(0)
      expect(job.promise_id).to eq(nil)
      expect(job.status).to eq('---')

      Timecop.travel(job.get_next_run + 1)

      mimic_scheduler
      job.reload

      promise_id = job.promise_id
      expect(job.processed).to eq(1)

      Timecop.travel(job.get_next_run + 1)

      mimic_scheduler
      job.reload

      expect(job.processed).to eq(2)

      # simulate a result not being nil by modifying params
      job.params = {'script_id' => 5}
      job.save!
      job.reload

      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler
      job.reload

      # job should now be completed and not be rescheduled
      expect(job.processed).to eq(3)
      expect(job.promise_id).to eq(nil)

      last_completed_dt = job.last_completed_dt
      Timecop.travel(30.minutes.from_now)
      mimic_scheduler
      job.reload

      # job should not have changed
      expect(job.last_completed_dt).to eq(last_completed_dt)
      expect(job.processed).to eq(3)
      expect(job.promise_id).to eq(nil)

      res = Marty::Promise.last.result
      expect(res).to_not eq(nil)
      expect(res).to eq({'script_id' => 5})
    end

    it 'supports multi attribute script calls' do
      Marty::Script.load_scripts(nil, Date.today)
      job = Marty::ScheduledJob.create!(
        second: '0',
        minute: '*',
        delorean_descriptor: {
          'script' => 'ScriptReport',
          'node'   => 'PrettyScript',
          'attrs'   => ['script_id', 'title'],
        },
        params: {
          'script_id' => 5,
        }
      )

      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      expect(Marty::ScheduledJob.where(
               description: 'ScriptReportPrettyScript'
             ).count(:id)).to eq(1)

      job.reload
      expect(job.last_completed_dt).to_not eq(nil)
      expect(job.status).to eq('Completed')

      expect(Marty::Promise.count(:id)).to eq(1)

      res = Marty::Promise.first.result
      expect(res).to_not include('error')
      expect(res).to include('script_id')
      expect(res).to include('title')
    end

    it 'can schedule a job to be run at a certain time' do
      job = Marty::ScheduledJob.create!(
        second: '0',
        minute: '*',
        delorean_descriptor: {
          'script' => 'ScriptReport',
          'node'   => 'PrettyScript',
          'attrs'   => 'script_id',
        },
        params: {
          'script_id' => nil
        }
      )

      expect(Marty::ScheduledJob.first.last_completed_dt).to eq(nil)

      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      job.reload
      expect(Marty::ScheduledJob.where(
               description: 'ScriptReportPrettyScript'
             ).count(:id)).to eq(1)

      expect(job.last_completed_dt).to_not eq(nil)
      expect(job.status).to eq('Completed')

      expect(Marty::Promise.count(:id)).to eq(1)
      res = Marty::Promise.first.result
      expect(res).to_not include('error')
      expect(res).to include('script_id')
    end

    it 'will not run jobs that are halted' do
      job = Marty::ScheduledJob.create!(
        second: '0',
        minute: '*',
        delorean_descriptor: {
          'script' => 'ScriptReport',
          'node'   => 'PrettyScript',
          'attrs'   => 'script_id',
        },
        params: {
          'script_id' => nil
        }
      )

      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      job.reload
      expect(job.processed).to eq(1)

      # go to next scheduled job and set halt to true
      job.update(halt: true)
      job.reload
      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      job.reload
      expect(job.processed).to eq(1)

      # go to next scheduled job and set halt to false
      job.update(halt: false)
      job.reload
      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      job.reload
      expect(job.processed).to eq(2)
    end

    it 'forces ownership of jobs/promises on current user' do
      user = Marty::User.create!(
        firstname: 'Test',
        lastname: 'User',
        login: 'test_user',
        active: true
      )

      Marty::User.current = user

      job = Marty::ScheduledJob.create!(
        second: '0',
        minute: '*',
        delorean_descriptor: {
          'script' => 'ScriptReport',
          'node'   => 'PrettyScript',
          'attrs'   => 'script_id',
        },
        params: {
          'script_id' => nil
        }
      )

      expect(job.user_id).to eq(user.id)

      Timecop.travel(job.get_next_run + 1)
      mimic_scheduler

      job.reload
      expect(job.processed).to eq(1)
      expect(job.last_completed_dt).to_not eq(nil)
      expect(Marty::Promise.last.user_id).to eq(user.id)
    end

    it 'schedules own restart and restarts correctly' do
      mimic_scheduler
      job = Marty::ScheduledJob.first
      expect(job).to_not be_nil
      expect(job.description).to eq('Marty Restart Scheduler')
      expect(job.processed).to eq(0)
      expect(job.scheduled_run_dt.to_s).to eq((job.created_at +
                                               Delayed::Worker.max_run_time -
                                               1.hour).to_s)

      Timecop.travel(job.scheduled_run_dt + 1)
      Marty::Delayed::Scheduler.new.deploy(job)

      # simulate running job as scheduler will update the last restart job
      # with a new scheduled_run_dt on re-deploy
      old_sl_created_at = Marty::SchedulerLife.last.created_at

      job.reload
      Delayed::Job.find(Marty::Promise.find(job.promise_id).job_id).invoke_job

      job.reload
      expect(job.last_completed_dt).to_not eq(nil)
      expect(Marty::SchedulerLife.last.created_at).to_not eq(old_sl_created_at)
    end

    it 'creates only one pg listener and closes it when scheduler dies' do
      Timecop.travel

      pre_conns = nil
      db = ActiveRecord::Base.connection.current_database
      with_delayed_job(n=4) do
        pre_conns = Marty::Diagnostic::Node.get_postgres_connections[db].
                      map{|a| a['application_name']}
      end
      post_conns = Marty::Diagnostic::Node.get_postgres_connections[db].
                     map{|a| a['application_name']}

      expect(pre_conns).to include('marty_scheduler_listener')
      expect(pre_conns.count('marty_scheduler_listener')).to eq(1)
      expect(post_conns).to_not include('marty_scheduler_listener')
    end
  end
end
