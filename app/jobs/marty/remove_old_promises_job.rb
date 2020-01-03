module Marty
  class RemoveOldPromisesJob < ::Marty::CronJob
    def perform
      ::Marty::Cleaner::Promises.call
    end
  end
end
