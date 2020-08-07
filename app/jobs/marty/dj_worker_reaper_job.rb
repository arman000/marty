module Marty
  class DJWorkerReaperJob < ::Marty::CronJob
    def perform
      system_login = Rails.configuration.marty.system_account

      current_node = Marty::MainAuthApp.my_ip
      Marty::Logger.info(name.to_s, "running on #{current_node}")
      res = Marty::MainAuthApp.bg_command('restart')
      "#{current_node}: #{res}"
    end
  end
end
