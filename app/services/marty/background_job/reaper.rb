module Marty
  module BackgroundJob
    module Reaper
      CONFIG_KEY = 'DELAYED_JOBS_MAINTENANCE_WINDOW'
      LOG_PREFIX = 'DelayedJobWorkerReaperJob'

      class << self
        def call
          # confirm that we are in the maintenance window for hte
          ::Marty::MaintenanceWindow.call(CONFIG_KEY)

          current_node = Marty::Diagnostic::Node.my_ip
          Marty::Logger.info(LOG_PREFIX, "running on #{current_node}")
          res = `#{Marty::MainAuthApp.new.bg_command('restart')}`
          Marty::Logger.info(LOG_PREFIX, "#{current_node}: #{res}")
          res
        end
      end
    end
  end
end
