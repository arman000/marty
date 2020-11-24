# frozen_string_literal: true

module Marty
  module RSpec
    module RequestRecording
      # Houses callbacks that are used by {RequestRecording}.
      module Callbacks
        module_function

        # This callback is run around each example and handles inserting the
        # correct VCR Cassette for the given example.
        #
        # @return [Proc] The callback.
        def insert_cassette
          lambda do |example|
            name = RequestRecording.cassette_name(example)
            delete_old_cassette!(name) if ::RSpec.configuration.recording?

            ::VCR.insert_cassette(name)
            example.run
            ::VCR.eject_cassette(name)
          end
        end
      end
    end
  end
end
