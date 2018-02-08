class Marty::Delayed::Scheduler
  def initialize
    @job_count = 0
  end

  def max_run_time
    4.hours
  end

  def max_attempts
    1
  end

  def queue_name
    'marty_scheduler'
  end

  def self.scheduler_sleep_time
    Marty::Config['SCHEDULER_HEARTBEAT'] || 60
  end

  def perform
    begin
      # create a raw postgres connection to listen to table changes
      listener = PG::Connection.open(
        dbname: ActiveRecord::Base.connection.current_database)
      listener.exec("SET application_name = 'marty_scheduler_listener';")
      listener.exec("LISTEN marty_scheduled_jobs")

      update_scheduler_life(init: true,
                            ip: Marty::Diagnostic::Node.my_ip,
                            pid: Process.pid)

      schedule_restart
      loop do
        update_scheduler_life(heartbeat: DateTime.now,
                              processed: @job_count)

        job              = next_job
        sleep_time       = self.class.scheduler_sleep_time
        time_to_next_job = job.nil? ? sleep_time : job.time_till

        if time_to_next_job.negative?
          begin
            deploy(job) unless job.reload.halt
          rescue ActiveRecord::RecordNotFound => e
            Marty::Util.logger.error("scheduled job does not exist: "\
                                     "#{e.message}")
          end
        else
          # timeout so we can produce heartbeat
          listener.wait_for_notify([sleep_time, time_to_next_job].min)
        end
      end
    ensure
      # unlisten and close raw pg connection
      if listener
        listener.exec("UNLISTEN *")
        listener.close
      end
    end
  end

  def next_job
    Marty::ScheduledJob.
      where("scheduled_run_dt::date = now()::date AND "\
            "promise_id IS NULL AND "\
            "halt IS FALSE AND "\
            "(last_completed_dt IS NULL OR "\
            "last_completed_dt < scheduled_run_dt)").
      order(:scheduled_run_dt).first
  end

  def update_scheduler_life opts={}
    sl = Marty::SchedulerLife.where(
      opts.delete(:init) ? {} : {pid: Process.pid}).first
    Thread.current.exit unless sl
    sl.update(opts)
  end

  def schedule_restart
    begin
      result = Marty::ScheduledJob.where(
        "last_completed_dt IS NULL AND "\
        "promise_id IS NULL AND "\
        "description = 'Marty Restart Scheduler' AND "\
        "halt IS FALSE"\
      ).to_a

      # get latest restart job and halt all other restart jobs that
      # haven't been processed.
      restart_job = result.pop
      result.each{|j| j.update(halt: true)}

      # restart 1 hour before worker max run time to play it safe
      cron = Marty::ScheduledJob.get_cron_hash_from_time(
        Time.now + Delayed::Worker.max_run_time - 1.hours)

      # reschedule latest restart job or create a restart job
      if restart_job
        restart_job.update(cron)
      else
        Marty::ScheduledJob.create!(
          {
            max_attempts: 1,
            delorean_descriptor: {
              'script' => 'Scheduler',
              'node'   => 'Restart',
              'attrs'  => 'perform',
            },
          } + cron
        )
      end
    rescue => e
      Marty::Util.logger.error("failed to schedule restart: "\
                               "#{e.message}")
    end
  end

  def self.with_transaction_lock
    ActiveRecord::Base.transaction do
      begin
        conn = ActiveRecord::Base.connection
        conn.execute("LOCK marty_scheduler_lives "\
                     "IN ACCESS EXCLUSIVE MODE "\
                     "NOWAIT;")
        yield conn
      rescue => e
        return if e.message.include? "not obtain lock"
        raise e
      end
    end
  end

  # should be called after rails initialization.
  # all rails instances attempt to create a delayed job;
  # the first to lock the table creates the job;
  # any delayed worker on a node can become the scheduler.
  def self.deploy
    with_transaction_lock do |conn|
      Marty::SchedulerLife.where(
        "heartbeat < NOW() - INTERVAL "\
        "'#{conn.quote(scheduler_sleep_time)} seconds'").delete_all

      return if Marty::SchedulerLife.exists?

      Marty::SchedulerLife.create!
      Delayed::Job.enqueue(Marty::Delayed::Scheduler.new)
    end
  end

  # the deploy intance method is used to deploy scheduled jobs.
  # it generates a promise for each work item.
  def deploy(job)
    promise = Marty::Promise.create!(user_id: job.user_id,
                                     title: "#{job.gen_identifier}")

    Marty::ScheduledJob.where(id: job.id).update_all(promise_id: promise.id)
    sj = Delayed::Job.enqueue(Work.new(promise, job))

    Marty::Promise.where(id: promise.id).
      update_all(job_id: sj.id, queue: sj.queue)

    @job_count += 1
  end

  class Work < Struct.new(:promise, :job)
    def queue_name
      'scheduled_jobs'
    end

    def perform
      Marty::ScheduledJob.where(id: job.id).update_all(status: 'Deployed')
      Marty::Promise.where(id: promise.id).update_all(start_dt: DateTime.now)

      script, node, attrs = ['script', 'node', 'attrs'].map do
        |m|
        job.delorean_descriptor[m]
      end

      res = nil
      begin
        Timeout::timeout(scheduler_max_job_time) do
          engine = Marty::ScriptSet.new.get_engine(script)

          Mcfly.whodunnit = promise.user
          begin
            attrs_eval = engine.evaluate(node, attrs, job.params)
            attrs      = [attrs] unless attrs.is_a?(Array)
            attrs_eval = [attrs_eval] unless attrs_eval.is_a?(Array)
            res        = Hash[attrs.zip(attrs_eval)]

          rescue => exc
            res = Delorean::Engine.grok_runtime_exception(exc)
          end
        end
      rescue => e
        res = {'error' => e.message}
      end

      Marty::Promise.where(id: promise.id).update_all(
        end_dt: DateTime.now,
        result: res,
        status: res["error"].nil?,
      )

      # determine appropriate status to return
      limit      = job.max_attempts
      got_result = !res.values.include?(nil)
      status     = res['error'] ? "Error" :
                     (limit.nil? || got_result ? "Completed" :
                        (job.processed + 1 == limit ? 'Failed' : "Polling"))

      # update scheduled job with results
      job_update = {
        got_result:        got_result,
        last_completed_dt: DateTime.now,
        processed:         job.processed + 1,
        promise_id:        nil,
        status:            status,
      }

      Marty::ScheduledJob.where(id: job.id).update_all(
        job_update + {scheduled_run_dt: job.get_next_run(job_update)}
      )
    end

    def scheduler_max_job_time
      Marty::Config['SCHEDULER_MAX_JOB_TIME'] || 5.minutes
    end
  end
end
