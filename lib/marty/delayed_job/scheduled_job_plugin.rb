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
              job_class_str = job.handler.split("\n").find do |line|
                line.include? 'job_class'
              end
              job_class_name = job_class_str.gsub('job_class:', '').strip
              job_class = job_class_name.constantize
              job.cron = job_class.cron_expression
            rescue StandardError
            end
          else
            # No cron job - proceed as normal
            block.call(worker, job)
          end
        end
      end
    end
  end
end
