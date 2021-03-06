require 'marty/sql_servers/connection_config'

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
      self.delayed_ver = ENV['DELAYED_VER']
      self.diag_timeout = ENV['DIAG_TIMEOUT'] || 10
      self.diag_title = ENV['DIAG_TITLE'] || ::Marty::RailsApp.application_name
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
