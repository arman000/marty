# frozen_string_literal: true

module Marty
  module Diagnostic
    class Dashboard < Netzke::Base
      def configure(c)
        super
        c.layout = :border
        c.title = 'Diagnostic Dashboard'
        c.modal = true
        c.items = [
          { component: :report_view,
            region: :west,
            width: '20%',
            scrollable: true,
            split: true },
          { component: :configuration_view,
            region: :center,
            width: '80%',
            scrollable: true,
            split: true }
        ]
        c.lazy_loading = true
        c.width = 800
        c.height = 700
        c.bbar = []
      end

      component :report_view do |c|
        c.klass = ReportView
      end

      component :configuration_view do |c|
        c.klass = ConfigurationView
      end
    end
  end
end
