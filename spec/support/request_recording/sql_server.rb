# frozen_string_literal: true

require 'marty/sql_servers/client'
require_relative 'callbacks/sql_server'
require_relative 'sql_server/cassette'
require_relative 'sql_server/client_fakes'
require_relative 'sql_server/errors'

module Marty
  module RSpec
    module RequestRecording
      # Handles recording requests sent through {Marty::SqlServers},
      # much like VCR does with HTTP.
      #
      # Users can pass settings through example metadata to control the module,
      # specifically through the `sql_server` key.
      # Passing +sql_server: { episode_check: false }+, for example, will
      # skip checking the consistency of the +episode+ file (to see if the
      # request being sent matches exactly the recorded request).
      module SqlServer
        CASSETTE_HOME = Rails.root.join('spec/cassettes/sql_server')

        # The current {SqlServer::Cassette} loaded into the RSpec example
        attr_accessor :cassette

        module_function

        # Configures RSpec by +include+ing {RequestRecording::SqlServer}
        # and defining the callbacks to use when recording or reading.
        def configure_rspec!
          ::RSpec.configure do |config|
            config.include Marty::RSpec::RequestRecording::SqlServer
            if config.recording?
              config.around(:example, &Callbacks::SqlServer.recording_callback)
            else
              config.before(:example, &Callbacks::SqlServer.reading_callback)
            end
          end
        end
      end
    end
  end
end

Marty::RSpec::RequestRecording::SqlServer.configure_rspec!
