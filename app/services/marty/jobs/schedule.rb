module Marty
  module Jobs
    module Schedule
      extend Delorean::Functions

      delorean_fn :call, sig: 0 do
        glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
        Dir.glob(glob).each { |f| require f }

        Marty::CronJob.subclasses.map do |klass|
          klass.schedule
          [klass.name, klass.cron_expression]
        end
      end
    end
  end
end
