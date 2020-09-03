module Marty
  module BackgroundJob
    module FetchMissingInScheduleCronJobs
      def self.call
        return call_sidekiq if Marty::Config['USE_SIDEKIQ_WITH_PROMISES']

        in_dashboard = Marty::BackgroundJob::Schedule.all

        names_conditions = in_dashboard.map do |schedule|
          "%job_class: #{schedule.job_class}\n%"
        end

        djs = Delayed::Job.
          where.not(cron: nil).
          where.not(cron: '').
          where("handler ILIKE '%job_class:%'")

        djs.where.not('handler ILIKE ANY ( array[?] )', names_conditions).
          or(djs.where.not(schedule_id: in_dashboard.map(&:id)))
      end

      def self.call_sidekiq
        in_dashboard = Marty::BackgroundJob::Schedule.all

        in_dashboard_ids = in_dashboard.map(&:id).map(&:to_s)

        names_conditions = in_dashboard.map do |schedule|
          "%job_class: #{schedule.job_class}\n%"
        end

        jobs = ::Sidekiq::Cron::Job.all.select do |job|
          next false if in_dashboard_ids.include?(job.name.split(' ').first)

          true
        end

        jobs
      end
    end
  end
end
