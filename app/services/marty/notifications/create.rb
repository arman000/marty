module Marty
  module Notifications
    module Create
      extend Delorean::Functions

      delorean_fn :call do |event_type:, text:|
        notification, deliveries = ActiveRecord::Base.transaction do
          notification = ::Marty::Notifications::Notification.create!(
            event_type: event_type,
            text: text,
            state: :pending
          )

          # FIXME: We should consider processing deliveries in the background
          deliveries = ::Marty::Notifications::CreateDeliveries.call(
            notification: notification
          )

          [notification, deliveries]
        end

        deliveries.each do |delivery|
          ::Marty::Notifications::ProcessDelivery.call(
            delivery: delivery
          )
        end

        notification.set_processed!

        {
          id: notification.id,
          event_type: event_type,
          text: text,
          state: notification.state,
        }
      end
    end
  end
end
