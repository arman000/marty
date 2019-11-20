module Marty
  module Notifications
    module ProcessDelivery
      class << self
        def call(delivery:)
          delivery.processor.call(delivery: delivery)
        end
      end
    end
  end
end
