module Marty
  module BackgroundJob
    module FetchMissingInScheduleCronJobs
      def self.call
        in_dashboard = Marty::BackgroundJob::Schedule.pluck(:job_class)

        names_conditions = in_dashboard.map do |job_class_name|
          "%job_class: #{job_class_name}\n%"
        end

        Delayed::Job.
          where.not(cron: nil).
          where.not(cron: '').
          where("handler ILIKE '%job_class:%'").
          where.not('handler ILIKE ANY ( array[?] )', names_conditions)
      end
    end
  end
end
