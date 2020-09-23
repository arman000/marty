require_relative 'grid_view'

module Marty
  module Notifications
    class Window < Netzke::Window::Base
      def configure(c)
        super

        c.title     = 'Notifications'
        c.modal     = true
        c.items     = [:grid_view]
        c.lazy_loading = true
        c.width = 800
        c.height = 550
      end

      component :grid_view do |c|
        c.klass = Marty::Notifications::GridView
        c.rows_per_page = 30
      end
    end
  end
end
