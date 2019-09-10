module Marty
  class RemoveOldPromisesJob < ::Marty::CronJob
    def perform
      Marty::Promise.cleanup(false)
    end
  end
end
