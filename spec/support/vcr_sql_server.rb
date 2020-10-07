# frozen_string_literal: true

# Only required like this because `app/services` is not yet in $LOAD_PATH.
marty_path = Gem.loaded_specs['marty'].full_gem_path
require "#{marty_path}/app/services/marty/sql_server"

module Marty
  module RSpec
    # This module borrows its name from the `vcr` gem.
    # It is used to record requests and responses sent to various SQL Server
    # systems. These SQL Server systems are contacted directly using the
    # `tiny_tds` gem, and are auxillary to the main database.
    module VcrSqlServer
      CASSETTE_DIR = Rails.root.join('spec/sql_server_cassettes')
      TARGET_CALLER_PATH = Rails.root.join('spec').to_s

      class ConnectionNotAllowedError < StandardError; end
      class MockClient
        def initialize(l)
          @l = l
        end

        def active?
          true
        end

        def execute(sql)
          @l.call(sql)
        end

        def sqlsent?
          false
        end

        def close; end
      end

      module_function

      def make_directory
        Dir.mkdir(CASSETTE_DIR) unless File.exist?(CASSETTE_DIR)
      end

      def resolve_file_name
        loc = caller_locations[3..-1].detect do |l|
          l.path.include?(TARGET_CALLER_PATH)
        end

        file_name = File.basename(loc.path, '.rb')
        "#{file_name}_#{loc.lineno}"
      end

      def raise_for_fixture_file(file_path)
        raise ConnectionNotAllowedError, <<~ERROR unless File.exist?(file_path)
          There are no sql server cassettes available to use. Please
          re-run spec test with REGEN=true to create cassettes.
        ERROR
      end

      def transform_hashes(hashes)
        hashes.map do |h|
          h.transform_values do |v|
            next v unless v.is_a?(String)

            v.to_f.to_s == v ? BigDecimal(v) : v
          end
        end
      end

      def connection(config_prefix, &block)
        file_path = "#{CASSETTE_DIR}/#{resolve_file_name}.json"
        if ENV['REGEN'] == 'true'
          method_result = Marty::SqlServer.og_connection(config_prefix, &block)

          return method_result unless method_result.is_a?(TinyTds::Client)

          return MockClient.new(
            lambda do |sql|
              result = method_result&.execute(sql)
              File.open(file_path, 'w+') do |f|
                f.write(JSON.pretty_generate(result.to_a))
              end
              result
            end
          )
        end

        raise_for_fixture_file(file_path)

        data = transform_hashes(JSON.parse(File.read(file_path)))
        MockClient.new(lambda { |_sql|
          OpenStruct.new(
            count: data.empty? ? 0 : 1,
            cancel: nil,
            to_a: data,
            sqlsent?: false,
            return_code: 0
          )
        })
      end

      def exec_query(config_prefix, query)
        file_path = "#{CASSETTE_DIR}/#{resolve_file_name}.json"
        if ENV['REGEN'] == 'true'
          result = Marty::SqlServer.og_exec_query(config_prefix, query)
          File.open(file_path, 'w+') do |f|
            f.write(JSON.pretty_generate(result.to_a))
          end

          return result
        end

        raise_for_fixture_file(file_path)

        transform_hashes(JSON.parse(File.read(file_path)))
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

        Marty::RSpec::VcrSqlServer.make_directory
      end
    end
  end
end

Marty::RSpec::VcrSqlServer.mock
