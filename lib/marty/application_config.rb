require 'pry'
module Marty
   class ApplicationConfig < ActiveSupport::OrderedOptions
     cattr_accessor :validators, default: {}

     def initialize(default_value = nil)
       set_validators
       super
       set_defaults
     end

     def []=(key, value)
      sym = key.to_sym
      validators[sym].call(value) if validators[sym]

      super(sym, value)
    end

     def set_defaults
       if methods.include?("set_defaults_#{Rails.env}".to_sym)
         send("set_defaults_#{Rails.env}")
       else
         set_defaults_common
       end
     end

     def set_validators
      validators[:role_type] = lambda do |klass|
        raise "'#{klass}' must be a Class" unless klass.is_a?(Class)

        [:values, :table_name].each do |m|
          raise "'#{klass}' missing '#{m}' method" unless klass.respond_to?(m)
        end
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
   end
end
