# Credit to: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/spec/simplecov_env.rb

require 'simplecov'
require 'logger'
require 'active_support/core_ext/numeric/time'

module Marty
  module SimpleCovHelper
    LOGGER = ::Logger.new(STDOUT)

    def self.merge_all_results!
      resultset_files = Pathname.glob(
        File.join(SimpleCov.coverage_path, '**', '.resultset.json')
      )

      result_array = begin
                      resultset_files.map do |result_file|
                        SimpleCov::Result.from_hash JSON.parse(result_file.read)
                      end
      rescue StandardError => e
                      {}
                     end

      merged = SimpleCov::ResultMerger.merge_results(*result_array)
      merged.format!

      # Print out to console all the groups and their percents + hits/line.
      groups = merged.groups.map do |group, files|
        [group, files.covered_percent, files.covered_strength]
      end
      sorted_groups = groups.sort_by { |_gr, per, _str| -per }
      sorted_groups.each do |group|
        gr_name, percent, strength = group
        LOGGER.info(
          "Group '#{gr_name}': #{percent} covered at #{strength} hits/line"
        )
      end
    end

    def self.configure_job
      # This should only be run as part of an RSpec pipeline
      return unless defined?(RSpec)

      SimpleCov.configure do
        if Rails.application.config.marty.gitlab_ci
          job_name = Rails.application.config.marty.ci_job_name
          coverage_dir "coverage/#{job_name}"
          command_name job_name
          SimpleCov.at_exit { SimpleCov.result }
        else
          command_options = RSpec::Core::ConfigurationOptions.new(ARGV)
          rspec_directories = command_options.options[:files_or_directories_to_run]
          case rspec_directories.length
          when 1
            category = Dir.exist?(rspec_directories[0]) ? rspec_directories[0] : nil
            coverage_dir "coverage/#{category}"
            command_name category
          else
            coverage_dir 'coverage/'
          end
        end
      end
    end

    def self.configure_profile
      SimpleCov.configure do
        load_profile 'test_frameworks'
        load_profile 'root_filter'
        load_profile 'bundler_filter'
        track_files '{app,lib,config}/**/*.rb'
        track_files 'db/seeds.rb'

        add_filter '/vendor/ruby/'
        add_filter 'spec/'

        add_group 'Libraries',         'lib'
        add_group 'Assets',            'app/assets'
        add_group 'Channels',          'app/channels'
        add_group 'Netzke Components', 'app/components'
        add_group 'Controllers',       'app/controllers'
        add_group 'Helpers',           'app/helpers'
        add_group 'Jobs',              'app/jobs'
        add_group 'Models',            'app/models'
        add_group 'Services',          'app/services'
        add_group 'Views',             'app/views'

        use_merging true
        merge_timeout 365.days
      end
    end

    def self.start!
      return unless Rails.application.config.marty.coverage

      configure_profile
      configure_job

      SimpleCov.start
    end
  end
end
