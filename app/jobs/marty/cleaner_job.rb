module Marty
  class CleanerJob < ::Marty::CronJob
    def perform
      system_login = Rails.configuration.marty.system_account
      Marty::Logger.info("Starting CleanerJob as user: #{system_login}")
      system_user = Marty::User.find_by(login: system_login)

      Marty::Promises::Ruby::Create.call(
        module_name: 'Marty::Cleaner::CleanAll',
        method_name: 'call',
        method_args: [],
        params: { _user_id: system_user&.id }
      )
    end
  end
end
