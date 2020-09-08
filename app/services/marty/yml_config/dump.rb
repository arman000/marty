# frozen_string_literal: true

module Marty
  module YmlConfig
    module Dump
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')
      SECRETS = ['credential', 'password', 'secret', 'key'].freeze

      module_function

      def config_keys_used_in_files
        `git grep -oP "Config\\['.*'\\]"`.scan(/Config\['(.*)'\]/).flatten.uniq
      end

      def all_configs
        code_configs = LoadFromGit.call
        yml_configs = Load.call
        configs = Marty::Config.all
        config_keys = configs.map { |c| c.key.downcase }
        yml_keys = yml_configs.keys - config_keys
        code_keys = code_configs.keys - yml_keys - config_keys
        all = code_keys.map { |k| code_configs[k] } +
              configs +
              yml_keys.map { |k| yml_configs[k] }

        binding.pry
        all.sort_by { |config| config.key.downcase }
      end

      def mask_secret(key, value)
        SECRETS.any? { |s| key.include?(s) } ? 'null' : value
      end

      def entry(key, value, description)
        <<~YML
          #{key}:
              default_value: >
                #{value.to_json}
              description: #{description || 'null'}
        YML
      end

      def call(yml_path = DEFAULT_PATH)
        entries = all_configs.map do |entry|
          key = entry.key.downcase
          value = mask_secret(key, entry.value.first)
          entry(key, value, entry.description)
        end

        File.open(yml_path, 'w+').write(entries.join("\n"))
      end
    end
  end
end
