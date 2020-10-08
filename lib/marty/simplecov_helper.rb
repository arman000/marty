# Credit to: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/spec/simplecov_env.rb

require 'marty/simplecov_profile'
require 'logger'

module Marty
  module SimpleCovHelper
    LOGGER = ::Logger.new(STDOUT)

    def self.merge_all_results!
      SimpleCov.collate(Dir['coverage/**/.resultset.json'], :marty) do
        coverage_dir 'coverage/'
        command_name 'merged'
      end

      merged_result = SimpleCov::ResultMerger.merged_result

      # Print out to console all the groups and their percents + hits/line.
      groups = merged_result.groups.map do |group, files|
        [group, files.covered_percent, files.covered_strength]
      end

      sorted_groups = groups.sort_by { |_gr, per, _str| -per }
      sorted_groups.each do |group|
        gr_name, percent, strength = group
        LOGGER.info(
          "Group '#{gr_name}': #{percent} covered at #{strength} hits/line"
        )
      end

      merged_result.format!
    end

    def self.start!
      return unless ENV['COVERAGE'] == 'true'

      SimpleCov.start :marty
    end
  end
end
