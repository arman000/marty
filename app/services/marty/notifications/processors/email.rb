module Marty
  module Notifications
    module Processors
      module Email
        class << self
          def call(delivery:)
            raise 'Not implemented!'
          end
        end
      end
    end
  end
end
