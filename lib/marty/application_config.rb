module Marty
   class ApplicationConfig < ActiveSupport::OrderedOptions
     def initialize(default_value = nil)
       super
       set_defaults
     end

     def set_defaults
       if methods.include?("set_defaults_#{Rails.env}".to_sym)
         send("set_defaults_#{Rails.env}")
       else
         set_defaults_common
       end
     end

     def set_defaults_common
       self.aws_request_timeout = ENV['AWS_REQUEST_TIMEOUT'] || 0.25
       self.ci_job_name = ENV['CI_JOB_NAME'] || nil
       self.coverage = ENV['COVERAGE'] == 'true'
       self.data_grid_plpg_lookups = false
       self.default_posting_type = 'BASE'
       self.delayed_ver = ENV['DELAYED_VER']
       self.diag_timeout = ENV['DIAG_TIMEOUT'] || 10
       self.diag_title = ENV['DIAG_TITLE'] || ::Marty::RailsApp.application_name
       self.enable_action_cable = true
       self.extjs_theme = 'classic'
       self.gitlab_ci = ENV['GITLAB_CI']
       self.load_dir = ENV['LOAD_DIR']
       self.promise_job_enqueue_hooks = []
       self.redis_url = nil
     end

     def self.action_mailer_defaults
       e = Rails.env
       app_name = ::Marty::RailsApp.application_name.downcase

       ActionMailer::Base.configure do |amc|
         amc.raise_delivery_errors = !e.production?
         amc.preview_path = Rails.root.join('spec/mailers/previews')
         amc.delivery_method = :smtp
         amc.default_options = {
           from: "#{app_name}-#{e}@#{ENV['MAILER_SMTP_DOMAIN']}",
         }
         amc.smtp_settings = {
           address: ENV['MAILER_SMTP_ADDRESS'],
           port: ENV['MAILER_SMTP_PORT']&.to_i,
           domain: ENV['MAILER_SMTP_DOMAIN'],
           authentication: ENV['MAILER_AUTHENTICATION']&.to_sym,
           user_name: ENV['MAILER_SMTP_USERNAME'],
           password: ENV['MAILER_SMTP_PASSWORD']
         }.compact
         amc
       end
     end
   end
end
