class Marty::CronJob < ActiveJob::Base
  around_perform do |_job, block|
    begin
      block.call
      log_success
    rescue StandardError => e
      log_failure(e)
      raise e
    end
  end

  def log_failure(exception)
    error = {
      message: exception.message,
      backtrace: exception.backtrace
    }

    ::Marty::BackgroundJob::Log.create!(
      job_class: self.class.name,
      status: :failure,
      error: error
    )
  end

  def log_success
    ::Marty::BackgroundJob::Log.create!(
      job_class: self.class.name,
      status: :success
    )
  end

  class << self
    def schedule
      return reschedule if scheduled?

      cron = cron_expression

      return if cron.blank?

      set(cron: cron).perform_later
    end

    def reschedule
      dj = delayed_job
      return dj.update(cron: cron_expression) if dj.locked_by?

      remove
      schedule
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    alias remove_schedule remove

    def scheduled?
      delayed_job.present?
    end

    def delayed_job
      Delayed::Job.
        where('handler LIKE ?', "%job_class: #{name}\n%").
        first
    end

    def cron_expression
      ::Marty::BackgroundJob::Schedule.on.find_by(job_class: name)&.cron
    end
  end
end
