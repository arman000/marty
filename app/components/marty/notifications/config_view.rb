module Marty
  module Notifications
    class ConfigView < Marty::Grid
      include Marty::Extras::Layout

      has_marty_permissions create: [:admin, :user_manager],
                            read:   [:admin, :user_manager],
                            update: [:admin, :user_manager],
                            delete: [:admin, :user_manager]

      def configure(c)
        super

        c.attributes = [:event_type, :recipient__name, :delivery_type, :state, :text]

        c.title ||= I18n.t('notifications_config', default: 'Notifications Configuration')
        c.model = 'Marty::Notifications::Config'
        c.editing = :in_form
        c.paging = :pagination
        c.store_config.merge!(
          sorters: [{ property: :id, direction: 'DESC', }]
        )
      end

      attribute :event_type do |c|
        c.width = 200
        enum_column(c, ::Marty::Notifications::EventType, nil, false)
      end

      attribute :recipient__name do |c|
        c.width = 200
      end

      attribute :delivery_type do |c|
        enum_column(c, model::AVAILABLE_TYPES, nil, false)
        c.width = 70
      end

      attribute :state do |c|
        enum_column(c, model.state_machines[:state].states.map(&:value), nil, false)
        c.width = 70
        c.label = I18n.t('notifications_config_state', default: 'On/Off')
      end

      attribute :text do |c|
        c.width = 400
        c.label = I18n.t('notifications_config_text', default: 'Message text')
        c.setter = lambda do |record, value|
          next record.text = '' if value.nil?

          record.text = value
        end
      end
    end
  end
end
