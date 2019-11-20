module Marty
  module Notifications
    module Processors
      module Web
        class << self
          def call(delivery:)
            delivery.set_sent!
            notify_websocket(delivery: delivery)
          end

          private

          def notify_websocket(delivery:)
            return unless Rails.application.config.marty.enable_action_cable

            unread_notifications_count = delivery.recipient&.unread_web_notifications_count

            ActionCable.server.broadcast(
              "marty_notifications_#{delivery.recipient_id}",
              unread_notifications_count: unread_notifications_count
            )
          end
        end
      end
    end
  end
end
