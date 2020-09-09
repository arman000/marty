# frozen_string_literal: true

module Marty
  module Configs
    module CreateYml
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')
      SECRETS = ['credential', 'password', 'secret', 'key'].freeze

      module_function

      def all_configs
        code_configs = Grep.call.map { |k| LoadYml.mock(k) }.index_by(&:key)
        yml_configs = LoadYml.call

        [
          code_configs,
          Marty::Config.all.index_by(&:key),
          yml_configs
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

      def call(yml_path = DEFAULT_PATH)
        entries = all_configs.map do |key, entry|
          value = mask_secret(key, entry.value.first)
          entry(key, value, entry.description)
        end

        File.open(yml_path, 'w+').write(entries.join("\n"))
      end
    end
  end
end
