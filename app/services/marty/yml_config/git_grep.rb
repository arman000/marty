# frozen_string_literal: true

module Marty
  module YmlConfig
    module GitGrep
      module_function

      GREP_CMD = "git grep -oP \"Config\\['.*'\\]\" \":!*spec*\""
      GREP_REGEX = /Config\['(.*)'\]/

      def git_grep_config_keys(prepend = [])
        cmds = ([prepend] + [GREP_CMD]).join('; ')
        `#{cmds}`.scan(GREP_REGEX).flatten.uniq.map(&:downcase)
      end

      def gem_config_keys
        path = Gem.loaded_specs['marty'].full_gem_path
        git_grep_config_keys(["cd #{path}"])
      end

      def application_config_keys
        git_grep_config_keys
      end

      def call
        [application_config_keys, gem_config_keys].flatten.compact.sort
      end
    end
  end
end
