# frozen_string_literal: true

module Marty
  module RSpec
    module RequestRecording
      module SqlServer
        module Errors
          class CassetteNotFoundError < RuntimeError
            def initialize(example)
              flag_name = RequestRecording::RECORD_ENV_FLAG_NAME
              msg = <<~ERROR
                A cassette could not be found for this RSpec example:
                "#{example.metadata[:location]}"
                DESCRIPTION: "#{example.metadata[:description]}"

                You may create one by setting `ENV['#{flag_name}'] = true` and
                re-running your example.
              ERROR
              puts msg
              super(msg)
            end
          end
        end
      end
    end
  end
end
