module Marty
  class DelayedJobWorkerReaperJob < ::Marty::CronJob
    def perform
      current_node = Marty::Diagnostic::Node.my_ip
      Marty::Logger.info(
        'DelayedJobWorkerReaperJob',
        "running on #{current_node}",
      )

      res = `#{Marty::MainAuthApp.new.bg_command('restart')}`

      Marty::Logger.info(
        'DelayedJobWorkerReaperJob',
        "#{current_node}: #{res}",
      )
    end
  end
end
