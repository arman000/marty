module Marty
  module Notifications
    class Notification < Marty::Base
      self.table_name = 'marty_notifications'

      validates :state, :event_type, presence: true

      has_many(
        :deliveries,
        class_name: '::Marty::Notifications::Delivery',
        dependent: :destroy,
        foreign_key: :notification_id,
        inverse_of: :notification
      )

      state_machine :state, initial: :pending do
        state :pending
        state :processed

        event :set_processed do
          transition processed: same, pending: :processed
        end
      end
    end
  end
end
