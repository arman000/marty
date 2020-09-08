# frozen_string_literal: true

module Marty
  module YmlConfig
    module Load
      DEFAULT_PATH = Rails.root.join('config/marty/configs.yml')

      module_function

      # Parses a target yml file and returns a mapping of config keys to pseudo
      # OpenStruct/Config objects
      def call(yml_file = DEFAULT_PATH)
        dir = File.dirname(yml_file)
        Dir.mkdir(dir) unless Dir.exists?(dir)
        FileUtils.touch(yml_file)
        yml = YAML.load(File.open(yml_file, 'r+').read)
        return {} unless yml

        yml
      end
    end
  end
end
