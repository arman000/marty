module Marty
  class DelayedJobWorkerReaperJob < ::Marty::CronJob
    def perform
      ::Marty::BackgroundJob::Reaper.call
    end
  end
end
