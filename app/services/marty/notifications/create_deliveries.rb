module Marty
  module Notifications
    module CreateDeliveries
      class << self
        def call(notification:)
          configs(notification).map do |config|
            notification.deliveries.create!(
              state: :pending,
              delivery_type: config.delivery_type,
              recipient: config.recipient,
              text: config.text
            )
          end
        end

        def configs(notification)
          Marty::Notifications::Config.where(
            state: :on,
            event_type: notification.event_type
          )
        end
      end
    end
  end
end
