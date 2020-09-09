# frozen_string_literal: true

module Marty
  module Configs
    module LoadYml
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')

      module_function

      def mock(key, value = nil, description = nil)
        OpenStruct.new(
          key: key,
          value: value.as_json || [],
          description: description
        )
      end

      def call(yml_file = DEFAULT_PATH)
        dir = File.dirname(yml_file)
        Dir.mkdir(dir) unless Dir.exist?(dir)
        FileUtils.touch(yml_file)
        yml = YAML.load(File.open(yml_file, 'r+').read)
        return {} unless yml

        yml.map { |k, v| mock(k, v['default_value'], v['description']) }.
          index_by(&:key)
      end
    end
  end
end
