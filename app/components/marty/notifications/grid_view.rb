module Marty
  module Notifications
    class GridView < Marty::Grid
      has_marty_permissions read: :any,
                            create: nil,
                            update: nil,
                            delete: nil

      def configure(c)
        super

        c.header = false
        c.model = 'Marty::Notifications::Delivery'
        c.attributes = [:created_at, :notification__event_type, :text, :error_text]
        c.store_config.merge!(
          sorters: [{ property: :created_at, direction: 'DESC' }],
          page_size: 30
        )

        c.scope = ->(arel) { arel.includes(:notification) }
      end

      def get_records(params)
        model.where(
          delivery_type: :web,
          state: [:sent, :delivered],
          recipient_id: Mcfly.whodunnit
        ).scoping do
          super
        end
      end

      def default_bbar
        []
      end

      attribute :notification__event_type do |config|
        config.width = 150
        config.label = 'Event'
      end

      attribute :text do |config|
        config.width = 300

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
