# frozen_string_literal: true

module Marty
  module RSpec
    module RequestRecording
      module Callbacks
        module SqlServer
          module_function

          # Callback used when recording.
          #
          # Creates a {RequestRecording::SqlServer::Cassette} for the example,
          # and then listens in to queries coming in which are stored in
          # memory and saved after the example runs.
          #
          # @return [Proc]
          def recording_callback
            lambda do |example|
              @cassette ||= RequestRecording::SqlServer::Cassette.new(example)
              # Listen in to SQL Server queries so we can write to cassette
              subs = ActiveSupport::Notifications.subscribe('sql.sqlserver') do |*args|
                event = ActiveSupport::Notifications::Event.new(*args)
                @cassette.database_interactions << {
                  **event.payload,
                  recorded_at: event.end
                }
              end

              # Run the test
              example.run

              # Unsubscribe from events now that test is done
              ActiveSupport::Notifications.unsubscribe(subs)

              # Don't write anything if no DB interactions were recorded
              next if @cassette.database_interactions.empty?

              # Write Cassette
              @cassette.write_to_file!
            end
          end

          # @return [Proc]
          def reading_callback
            lambda do |example|
              @cassette = RequestRecording::SqlServer::Cassette.for_example(example)
            end
          end
        end
      end
    end
  end
end
