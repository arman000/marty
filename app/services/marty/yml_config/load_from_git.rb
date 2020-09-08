# frozen_string_literal: true

module Marty
  module YmlConfig
    module LoadFromGit
      module_function

      def config_keys_used_in_files
        `git grep -oP "Config\\['.*'\\]"`.scan(/Config\['(.*)'\]/).flatten.uniq.map(&:downcase)
      end

      # Returns a mapping of config keys to pseudo OpenStruct/Config objects
      def call
        config_keys_used_in_files.map do |k|
          OpenStruct.new(key: k, value: [])
        end.index_by(&:key)
      end
    end
  end
end
