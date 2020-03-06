class TestFailingJob < Marty::CronJob
  def perform
    self.class.trigger_destroy
    self.class.trigger_failure
  end

  def self.trigger_destroy
    dj = Marty::BackgroundJob::Schedule.find_by(
      job_class: 'TestFailingJob'
    ).delayed_job

    dj.destroy!
  end

  def self.trigger_failure
    raise 'failure triggered'
  end
end
