module Marty
  module Notifications
    class Config < Marty::Base
      self.table_name = 'marty_notifications_configs'

      AVAILABLE_TYPES = ::Marty::Notifications::Delivery.
        state_machines[:delivery_type].states.map(&:value)

      belongs_to :recipient, class_name: '::Marty::User'

      validates :recipient, presence: true

      validates :delivery_type, presence: true, inclusion: { in: AVAILABLE_TYPES }

      validates :delivery_type,
                presence: true,
                uniqueness: { scope: [:event_type, :recipient_id] }

      state_machine :state, initial: :on do
        state :off
        state :on
      end
    end
  end
end
