require 'simplecov'
require 'active_support/core_ext/numeric/time'

SimpleCov.profiles.define :marty do
  enable_coverage ENV.fetch('COVERAGE_METHOD', 'line').to_sym

  track_files '{app,config,lib,spec}/**/*.rb'

  add_filter 'db/migrate'
  add_filter 'vendor/'
  add_filter 'extjs/'

  add_group 'Channels', 'app/channels'
  add_group 'Netzke Components', 'app/components'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Jobs', ['app/jobs', 'app/workers']
  add_group 'Mailers', 'app/mailers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Configs', 'config/'
  add_group 'Libraries', 'lib/'
  add_group 'Specs', 'spec/'

  enable_for_subprocesses true
  at_fork do |pid|
    # This needs a unique name so it won't be ovewritten
    command_name "#{command_name} (subprocess: #{pid})"
    # be quiet, the parent process will be in charge of output and checking coverage totals
    print_error_status = false
    formatter SimpleCov::Formatter::SimpleFormatter
    minimum_coverage 0
  end

  use_merging true
  merge_timeout 1.day

  coverage_run_name = ENV.fetch('COVERAGE_RUN_NAME', 'rspec')
  coverage_dir "coverage/#{coverage_run_name}"
  command_name coverage_run_name

  if ENV['GITLAB_CI']
    job_name = ENV['CI_JOB_NAME']
    coverage_dir "coverage/#{job_name}"
    command_name job_name
    SimpleCov.at_exit { SimpleCov.result }
  end
end
