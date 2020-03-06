module Marty
  module DelayedJob
    class ScheduledJobPlugin < Delayed::Plugin
      class << self
        def cron?(job)
          job.cron.present?
        end
      end

      callbacks do |lifecycle|
        # We want to nullify cron column if job schedule was turned off
        # while the job was running, so it won't add a new record to
        # delayed_jobs table
        lifecycle.before(:error) do |worker, job, &block|
          if cron?(job)
            begin
              schedule = ::Marty::BackgroundJob::Schedule.find_by(id: job.schedule_id)

              if schedule&.on?
                job.cron = schedule.cron
                job.schedule_id = schedule.id
              else
                job.cron = nil
                job.schedule_id = nil
              end
            rescue StandardError
            end
          else
            # No cron job - proceed as normal
            block&.call(worker, job)
          end
        end
      end
    end
  end
end
