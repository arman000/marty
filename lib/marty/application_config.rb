require 'marty/sql_servers/connection_config'
require 'marty/diagnostic/git'

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
      self.data_grid_plpg_lookups = false
      self.default_posting_type = 'BASE'
      self.diagnostic_app_version = ENV['MARTY_DIAGNOSTIC_APP_VERSION'] || Marty::Diagnostic::Git.tag
      self.diagnostic_remote_timeout = ENV['MARTY_DIAGNOSTIC_REMOTE_TIMEOUT'] || 10
      self.diagnostic_title = ENV['MARTY_DIAGNOSTIC_TITLE'] || Marty::RailsApp.application_name
      self.enable_action_cable = true
      self.extjs_theme = 'classic'
      self.gitlab_ci = ENV['GITLAB_CI']
      self.load_dir = ENV['LOAD_DIR']
      self.promise_job_enqueue_hooks = []
      self.redis_url = nil
      self.sqlserver_connection_settings = Marty::SqlServers::ConnectionConfig.get_settings
    end
  end
end
