# frozen_string_literal: true

# Only required like this because `app/services` is not yet in $LOAD_PATH.
marty_path = Gem.loaded_specs['marty'].full_gem_path
require "#{marty_path}/app/services/marty/sql_server"

RSpec.configure do |config|
  config.around do |example|
    described_class = example&.metadata&.dig(:described_class)
    description = example&.description
    Marty::RSpec::VcrSqlServer.rspec_class = described_class
    Marty::RSpec::VcrSqlServer.rspec_description = description
    Marty::RSpec::VcrSqlServer.rspec_context = example&.metadata&.dig(:full_description)&.
                                                sub(described_class.to_s, '')&.
                                                sub(description, '')
    Marty::RSpec::VcrSqlServer.cassette_index = 0
    Marty::RSpec::VcrSqlServer.cassette_contents = []

    example.run

    Marty::RSpec::VcrSqlServer.write_cassette unless
      Marty::RSpec::VcrSqlServer.cassette_contents.empty?

    Marty::RSpec::VcrSqlServer.rspec_class = nil
    Marty::RSpec::VcrSqlServer.rspec_context = nil
    Marty::RSpec::VcrSqlServer.rspec_description = nil
  end
end

module Marty
  module RSpec
    # This module borrows its name from the `vcr` gem.
    # It is used to record requests and responses sent to various SQL Server
    # systems. These SQL Server systems are contacted directly using the
    # `tiny_tds` gem, and are auxillary to the main database.
    module VcrSqlServer
      CASSETTE_HOME = Rails.root.join('spec/sql_server_cassettes')

      class << self
        attr_accessor :cassette_contents
        attr_accessor :cassette_index
        attr_accessor :rspec_class
        attr_accessor :rspec_context
        attr_accessor :rspec_description
      end

      class ConnectionNotAllowedError < StandardError; end

      module_function

      def make_directories
        Dir.mkdir(CASSETTE_HOME) unless File.exist?(CASSETTE_HOME)

        folders = cassette_subdir.split('/')
        folders.each_with_index do |_, index|
          dirp = File.join(CASSETTE_HOME, folders.first(index + 1).join('/'))
          Dir.mkdir(dirp) unless File.exist?(dirp)
        end
      end

      def resolve_file_name
        file_name = [
          rspec_context.parameterize,
          rspec_description.parameterize
        ].compact.join('--')
      end

      def raise_for_fixture_file(file_path)
        raise ConnectionNotAllowedError, <<~ERROR unless File.exist?(file_path)
          There are no sql server cassettes available to use. Please
          re-run spec test with REGEN=true to create cassettes.
        ERROR
      end

      def cassette_subdir
        rspec_class.to_s.underscore
      end

      def cassette_filepath
        File.join(CASSETTE_HOME, cassette_subdir, "#{resolve_file_name}.yaml")
      end

      def record_stub(result)
        cassette_contents << result
      end

      def write_cassette
        make_directories

        File.open(cassette_filepath, 'w+') do |f|
          f.write(cassette_contents.to_yaml)
        end
      end

      def connection(config_prefix, &block)
        if ENV['REGEN'] == 'true'
          method_result = Marty::SqlServer.og_connection(config_prefix, &block)
          record_stub(method_result) if block_given?
          return method_result
        end

        raise_for_fixture_file(cassette_filepath)
        YAML.safe_load(File.read(cassette_filepath))[cassette_index]
      ensure
        self.cassette_index += 1
      end

      def exec_query(config_prefix, query)
        if ENV['REGEN'] == 'true'
          result = Marty::SqlServer.og_exec_query(config_prefix, query)
          record_stub(result)
          return result
        end

        raise_for_fixture_file(cassette_filepath)
        YAML.safe_load(File.read(cassette_filepath))[self.cassette_index]
      ensure
        self.cassette_index += 1
      end

      def mock
        return if Marty::SqlServer.respond_to?(:vcr_connection) ||
                  Marty::SqlServer.respond_to?(:vcr_exec_query)

        Marty::SqlServer.module_eval do
          define_singleton_method :vcr_connection do |*args, &block|
            Marty::RSpec::VcrSqlServer.connection(*args, &block)
          end
          define_singleton_method :vcr_exec_query do |*args|
            Marty::RSpec::VcrSqlServer.exec_query(*args)
          end

          class << self
            alias_method :og_connection, :connection
            alias_method :connection, :vcr_connection
            alias_method :with_connection, :vcr_connection

            alias_method :og_exec_query, :exec_query
            alias_method :exec_query, :vcr_exec_query
          end
        end
      end
    end
  end
end

Marty::RSpec::VcrSqlServer.mock
