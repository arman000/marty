# frozen_string_literal: true

module Marty
  module SqlServer
    module Errors
      class ConnectionNotEstablishedError < ::TinyTds::Error
        def initialize(msg = nil)
          super(['unable to connect to SQL Server', msg].compact.join(': '))
        end
      end
    end
  end
end
