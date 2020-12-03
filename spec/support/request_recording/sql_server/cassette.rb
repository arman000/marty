# frozen_string_literal: true

module Marty
  module RSpec
    module RequestRecording
      module SqlServer
        class Cassette
          attr_accessor :database_interactions
          attr_reader :metadata
          attr_reader :name
          attr_reader :path

          def initialize(example)
            @database_interactions = []
            @metadata = get_metadata(example)
            @name = RequestRecording.cassette_name(example)
            @path = SqlServer::CASSETTE_HOME.join("#{name}.yml")
            @example = example
          end

          def self.for_example(example)
            read_cassette = new(example)

            return nil unless File.exist?(read_cassette.path)

            loaded_yaml = YAML.load_file(read_cassette.path)
            read_cassette.database_interactions = loaded_yaml['database_interactions']
            read_cassette
          end

          def write_to_file!
            # In case corresponding folder doesn't exist
            FileUtils.mkdir_p(@path.parent)

            File.open(@path, 'w') do |cassette_file|
              cassette_file.write(to_yaml)
            end
          end

          def to_yaml
            {
              database_interactions: @database_interactions,
              metadata: @metadata
            }.as_json.to_yaml
          end

          private

          def get_metadata(example)
            {
              example_location: example.metadata[:location],
              example_description: example.metadata[:full_description],
              tiny_tds_version: ::TinyTds::VERSION,
            }
          end
        end
      end
    end
  end
end
