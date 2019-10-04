module Marty
  module Jobs
    module Schedule
      extend Delorean::Functions

      delorean_fn :call, sig: 0 do
        glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
        Dir.glob(glob).each { |f| require f }

        glob2 = Marty.root.join('app', 'jobs', '**', '*_job.rb')
        Dir.glob(glob2).each { |f| require f }

        Delayed::Job.where.not(cron: nil).each(&:destroy!)

        Marty::CronJob.subclasses.map do |klass|
          klass.schedule
          [klass.name, klass.cron_expression]
        end
      end
    end
  end
end
