# frozen_string_literal: true

module Marty
  module YmlConfig
    module Create
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')
      SECRETS = ['credential', 'password', 'secret', 'key'].freeze

      module_function

      def all_configs
        code_configs = GitGrep.call.map { |k| Load.mock(k) }.index_by(&:key)
        yml_configs = Load.call

        [
          code_configs,
          yml_configs,
          Marty::Config.all.index_by(&:key)
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
