namespace :marty do
  namespace :jobs do
    desc 'Schedule all cron jobs'
    task schedule: :environment do
      ::Marty::Jobs::Schedule.call
    end
  end
end
