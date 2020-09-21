# frozen_string_literal: true

module Marty
  module Configs
    module Grep
      module_function

      GREP_REGEX = /Config\[(?:'|")(\w+)(?:'|")\]/
      GREP_CMD = "git grep -oP \"#{GREP_REGEX.to_s.gsub('"', '\"')}\" \"*.rb\" \":!*db*\" \":!*spec*\""

      def git_grep_config_keys(commands = [])
        cmds = (commands + [GREP_CMD]).join('; ')
        `#{cmds}`.scan(GREP_REGEX).flatten.uniq
      end

      def call
        git_grep_config_keys.sort
      end
    end
  end
end
