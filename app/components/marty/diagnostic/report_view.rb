module Marty
  module Diagnostic
    class ReportView < Marty::Grid
      include Marty::Extras::Layout
      has_marty_permissions read: [:admin, :dev],
        create: [:admin],
        update: [:admin],
        delete: [:admin]

      def child_components
        [:configuration_view]
      end

      def configure(c)
        super

        c.title ||= I18n.t('diagnostic_report_view', default: 'Reports')
        c.model = 'Marty::Diagnostic::Report'
        c.editing = :in_form
        c.paging = :pagination
        c.attributes = [
          :name
        ]

        c.store_config[:sorters] = [{ property: :name, direction: 'ASC' }]
      end

      attribute :name do |c|
        c.flex = 1
      end
    end
  end
end
