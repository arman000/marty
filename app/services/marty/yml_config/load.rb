# frozen_string_literal: true

module Marty
  module YmlConfig
    module Load
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')

      module_function

      # Parses a target yml file and returns a mapping of config keys to pseudo
      # OpenStruct/Config objects
      def call(yml_file = DEFAULT_PATH)
        yml = YAML.load(File.read(yml_file))
        return {} unless yml

        yml.map do |k, v|
          value = JSON.parse(v['default_value'])
          OpenStruct.new(
            key: k,
            value: value || value == false ? [value] : [],
            description: v['description']
          )
        end.flatten.index_by(&:key)
      end
    end
  end
end
