# frozen_string_literal: true

module Marty
  module Configs
    module CreateYml
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')
      SECRETS = ['credential', 'password', 'key', 'secret'].freeze

      module_function

      def marty_yml_path
        path = Gem.loaded_specs['marty'].full_gem_path
        [path, 'config/configs.yml'].join('/')
      end

      def marty_configs
        LoadYml.call(path: marty_yml_path)
      end

      def create_marty_configs_yml
        gem_path = Gem.loaded_specs['marty'].full_gem_path
        yml_path = marty_yml_path
        default_yml = LoadYml.call(path: yml_path)
        grep_keys = Grep.git_grep_config_keys(["cd #{gem_path}"])
        missing_keys = grep_keys - default_yml.keys
        configs = [
          default_yml,
          missing_keys.map { |k| LoadYml.mock(k) }.index_by(&:key)
        ].reduce(&:merge).sort.to_h

        call(configs: configs, output: yml_path)
      end

      def all_configs
        code_configs = Grep.call.map { |k| LoadYml.mock(k) }.index_by(&:key)
        yml_configs = LoadYml.call

        [
          code_configs,
          Marty::Config.all.index_by(&:key),
          yml_configs,
          marty_configs,
        ].reduce(&:merge).sort.to_h
      end

      def mask_secret(key, value)
        downcased_key = key.downcase
        SECRETS.any? { |s| downcased_key.include?(s) } ? 'null' : value
      end

      def entry(key, value, description)
        <<~YML
          #{key}:
              default_value: >
                #{value.to_json}
              description: #{description || 'null'}
        YML
      end

      def call(configs: all_configs, output: DEFAULT_PATH)
        entries = configs.map do |key, entry|
          value = mask_secret(key, entry.value.first)
          entry(key, value, entry.description)
        end

        File.open(output, 'w+').write(entries.join("\n"))
      end
    end
  end
end
