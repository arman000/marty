class TestFailingJob < Marty::CronJob
  def perform
    self.class.trigger_destroy
    self.class.trigger_failure
  end

  def self.trigger_destroy
    delayed_job.destroy!
  end

  def self.trigger_failure
    raise 'failure triggered'
  end
end
