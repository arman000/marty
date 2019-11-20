module Marty
  module Notifications
    class Delivery < Marty::Base
      self.table_name = 'marty_notifications_deliveries'

      belongs_to :notification, class_name: '::Marty::Notifications::Notification'
      belongs_to :recipient, class_name: '::Marty::User'

      validates :state, presence: true

      # One delivery per type per notification for user
      validates :delivery_type,
                presence: true,
                uniqueness: { scope: [:notification_id, :recipient_id] }

      state_machine :delivery_type, initial: :web do
        state :web do
          def processor
            Marty::Notifications::Processors::Web
          end
        end

        # state :email do
        # def processor
        # Marty::Notifications::Processors::Email
        # end
        # end
        #
        # state :sms do
        # def processor
        # Marty::Notifications::Processors::Sms
        # end
        # end
      end

      state_machine :state, initial: :pending do
        state :pending
        state :sent
        state :delivered
        state :failed

        event :set_sent do
          transition [:pending, :failed] => :sent, sent: same
        end

        event :set_failed do
          transition [:pending, :sent] => :failed, failed: same
        end

        event :set_delivered do
          transition all => :delivered
        end
      end
    end
  end
end
