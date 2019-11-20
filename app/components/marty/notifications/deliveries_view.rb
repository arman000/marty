module Marty
  module Notifications
    class DeliveriesView < Marty::Grid
      ROLES_WITH_ACCESS = [:admin, :dev]

      has_marty_permissions read: ROLES_WITH_ACCESS,
                            create: nil,
                            update: nil,
                            delete: ROLES_WITH_ACCESS

      def configure(c)
        super

        c.header = false
        c.model = 'Marty::Notifications::Delivery'
        c.attributes = [:created_at, :notification__event_type, :recipient__name,
                        :state, :delivery_type, :text, :error_text]
        c.store_config.merge!(
          sorters: [{ property: :id, direction: 'DESC' }],
          page_size: 30
        )

        c.scope = ->(arel) { arel.includes(:notification).includes(:recipient) }
      end

      attribute :notification__event_type do |config|
        config.width = 150
        config.label = 'Event'
      end

      attribute :recipient__name do |config|
        config.width = 150
        config.label = 'Recipient'
      end

      attribute :text do |config|
        config.width = 400

        config.getter = lambda do |record|
          [record.notification.text, record.text].join(', ')
        end
      end

      attribute :error_text do |config|
        config.width = 300
        config.label = 'Error'
      end
    end
  end
end
