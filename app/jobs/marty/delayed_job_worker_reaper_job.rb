module Marty
  class DelayedJobWorkerReaperJob < ::Marty::CronJob
    LOG_PREFIX = 'DelayedJobWorkerReaperJob'

    def perform
      current_node = Marty::Diagnostic::Node.my_ip
      Marty::Logger.info(LOG_PREFIX, "running on #{current_node}")
      res = `#{Marty::MainAuthApp.new.bg_command('restart')}`
      Marty::Logger.info(LOG_PREFIX, "#{current_node}: #{res}")
    end
  end
end
