module Marty
  module BackgroundJob
    module FetchMissingInScheduleCronJobs
      def self.call
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
    end
  end
end
