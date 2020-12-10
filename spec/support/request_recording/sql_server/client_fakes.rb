# frozen_string_literal: true

require 'marty/sql_servers/client'

module Marty
  module RSpec
    module RequestRecording
      module SqlServer
        # This module patches {Marty::SqlServers::Client} to account for reading
        # of the current {SqlServer::Cassette} if {SqlServer.recording?} is
        # turned on.
        module ClientFakes
          # We don't want any connections if we're not recording
          def ensure_connection!
            ::RSpec.configuration.recording? ? super : true
          end

          private

          def instrument_query(method_name, sql, vars: {})
            return super if ::RSpec.configuration.recording?

            example = ::RSpec.current_example
            cassette = example.example_group_instance.cassette
            raise SqlServer::Errors::CassetteNotFoundError, example if cassette.nil?

            episode = cassette.database_interactions.shift
            episode_check = example.metadata.dig(:sql_server, :episode_check)
            check_episode_consistency!(episode, method_name, sql, vars) unless episode_check == false

            episode['result']
          end

          # Checks to see if the current episode from the cassette
          # matches the parameters sent to the query.
          #
          # @raise If not consistent
          def check_episode_consistency!(episode, method_name, sql, vars)
            raise 'Read SQL Server Episode is not a Hash' unless episode.is_a?(Hash)

            episode_database = episode['database']
            expected_database = {
              'host' => @spec.config[:host],
              'database' => @spec.config[:database],
            }
            raise 'Database in episode does not match current database!' unless
                  episode_database == expected_database

            episode_request = episode['request']
            expected_request = {
              'method_name' => method_name.to_s,
              'sql' => sql,
              'variables' => vars.empty? ? nil : vars
            }.compact
            raise 'Query in episode does not match given query!' unless
                  episode_request == expected_request.deep_stringify_keys
          end
        end
      end
    end
  end
end

Marty::SqlServers::Client.prepend(
  Marty::RSpec::RequestRecording::SqlServer::ClientFakes
)
