# frozen_string_literal: true

module Marty
  module Configs
    module LoadYml
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')

      module_function

      def mock(key, value = nil, description = nil)
        OpenStruct.new(
          key: key,
          value: value ? [JSON.parse(value)].compact : [],
          description: description
        )
      end

      def call(path: DEFAULT_PATH)
        dir = File.dirname(path)
        Dir.mkdir(dir) unless Dir.exist?(dir)
        FileUtils.touch(path)
        yml = YAML.safe_load(File.open(path, 'r+').read)
        return {} unless yml

        yml.map { |k, v| mock(k, v['default_value'], v['description']) }.
          index_by(&:key)
      end
    end
  end
end
