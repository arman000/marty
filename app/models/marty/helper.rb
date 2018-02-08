class Marty::Helper
  include Delorean::Model

  delorean_fn :sleep, sig: 1 do
    |seconds|
    Kernel.sleep seconds
  end

  delorean_fn :range_step, sig: 3 do
    |rstart, rend, step|
    (rstart..rend).step(step).to_a
  end

  delorean_fn :my_ip, sig: 0 do
    Marty::Diagnostic::Node.my_ip
  end

  delorean_fn :git, sig: 0 do
    [my_ip, ENV['DELAYED_VER']]
  end

  delorean_fn :restart_scheduler, sig: 0 do
    begin
      Marty::SchedulerLife.delete_all
      Marty::SchedulerLife.create!
      Delayed::Job.enqueue(Marty::Delayed::Scheduler.new)
      Marty::SchedulerLife.exists?
    rescue => e
      bindind.pry
      raise e
    end
  end

  # only cleans max_attempt jobs after a specified period
  delorean_fn :clean_scheduled_jobs, sig: 1 do
    |period|
    Marty::ScheduledJob.where(
      "(max_attempts > 0) AND "\
      "last_completed_dt < (now() - interval '? seconds')", period).delete_all
  end
end
