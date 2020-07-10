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

                # In delayed_cron_job >= 0.7.3 job recreation mechanism
                # is reworked so it doesn't recreate the job if it was deleting
                # during the execution. I'm not sure we should handle such cases,
                # but just to be safe we do.
                #
                # Recreate job if it was deleted during the execution
                unless Delayed::Job.where(id: job.id).exists?
                  new_job = job.dup
                  new_job.schedule_next_run
                end
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
