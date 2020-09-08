# frozen_string_literal: true

module Marty
  module YmlConfig
    module Dump
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')
      SECRETS = ['credential', 'password', 'secret', 'key'].freeze

      module_function

      def mock_config(key, value = nil, description = nil)
        OpenStruct.new(
          key: key,
          value: value.as_json || [],
          description: description
        )
      end

      def all_configs
        code_configs = GitGrep.call.map { |k| mock_config(k) }.index_by(&:key)
        yml_configs = Load.call.map do |k, v|
          mock_config(k, v['default_value'], v['description'])
        end.index_by(&:key)

        configs = [
          code_configs,
          yml_configs,
          Marty::Config.all.index_by(&:key)
        ].reduce(&:merge).sort.to_h
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
        entries = all_configs.map do |key, entry|
          value = mask_secret(key, entry.value.first)
          entry(key, value, entry.description)
        end

        File.open(yml_path, 'w+').write(entries.join("\n"))
      end
    end
  end
end
