class Marty::CronJob < ActiveJob::Base
  attr_accessor :schedule_id

  def enqueue(options = {})
    self.cron = options[:cron] if options[:cron]
    self.schedule_id = options[:schedule_id] if options[:schedule_id]
    super
  end

  around_perform do |job, block|
    begin
      block.call
      log_success(job.arguments)
    rescue StandardError => e
      log_failure(e, job.arguments)
      raise e
    end
  end

  def log_failure(exception, arguments)
    error = {
      message: exception.message,
      backtrace: exception.backtrace
    }

    ::Marty::BackgroundJob::Log.create!(
      job_class: self.class.name,
      arguments: arguments,
      status: :failure,
      error: error
    )
  end

  def log_success(arguments)
    ::Marty::BackgroundJob::Log.create!(
      job_class: self.class.name,
      arguments: arguments,
      status: :success
    )
  end

  class << self
    def schedule(schedule_obj:)
      dj = schedule_obj.delayed_job

      return reschedule(schedule_obj: schedule_obj) if dj.present?

      cron = schedule_obj.cron

      return if cron.blank?

      set(cron: cron, schedule_id: schedule_obj.id).perform_later(*schedule_obj.arguments)
    end

    def reschedule(schedule_obj:)
      dj = schedule_obj.delayed_job
      return dj.update(cron: schedule_obj.cron) if dj.locked_by?

      remove(dj)
      set(cron: schedule_obj.cron, schedule_id: schedule_obj.id).
        perform_later(*schedule_obj.arguments)
    end

    def remove(dj)
      dj.destroy if dj.present?
    end

    alias remove_schedule remove

    def scheduled?(schedule_id:)
      Delayed::Job.find_by(schedule_id: schedule_id).present?
    end
  end
end
