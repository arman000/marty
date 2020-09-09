# frozen_string_literal: true

module Marty
  module Configs
    module Grep
      module_function

      GREP_CMD = "git grep -oP \"Config\\['.*'\\]\" \":!*spec*\" \":!*db*\""
      GREP_REGEX = /Config\['(.*)'\]/

      def git_grep_config_keys(commands = [])
        cmds = (commands + [GREP_CMD]).join('; ')
        `#{cmds}`.scan(GREP_REGEX).flatten.uniq
      end

      def application_config_keys
        git_grep_config_keys
      end

      def call
        application_config_keys.sort
      end
    end
  end
end
