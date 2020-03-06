module Marty
  module Jobs
    module Schedule
      extend Delorean::Functions

      delorean_fn :call do
        glob = Rails.root.join('app/jobs/**/*_job.rb')
        Dir.glob(glob).sort.each { |f| require f }

        glob2 = Marty.root.join('app/jobs/**/*_job.rb')
        Dir.glob(glob2).sort.each { |f| require f }

        Delayed::Job.where.not(cron: nil).each(&:destroy!)

        Marty::BackgroundJob::Schedule.all.map do |schedule|
          Marty::BackgroundJob::UpdateSchedule.call(
            id: schedule.id,
            job_class: schedule.job_class,
          )

          [schedule.job_class, schedule.arguments, schedule.cron]
        end
      end
    end
  end
end
