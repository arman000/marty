module Marty
  module Diagnostic
    class ConfigurationView < Marty::Grid
      include Marty::Extras::Layout
      has_marty_permissions read: [:admin, :dev],
        create: [:admin],
        update: [:admin],
        delete: [:admin]

      def configure(c)
        super

        c.title ||= I18n.t('diagnostic_configuration_view', default: 'Configurations')
        c.model = 'Marty::Diagnostic::Configuration'
        c.editing = :in_form
        c.paging = :pagination
        c.attributes = [
          :name,
          :timeout,
          :enabled,
          :report__name
        ]

        c.scope = ->(r) { r.includes(:report).where({ report_id: client_config['parent_id'] }.compact) }
        c.store_config.merge!(sorters: [{ property: :name, direction: 'ASC' }])
      end

      attribute :name do |c|
        c.min_width = 350
        c.field_config = {
          trigger_action: :all,
          xtype: :combobox,
          store: Marty::Diagnostic.diagnostics.sort
        }
      end
    end
  end
end
