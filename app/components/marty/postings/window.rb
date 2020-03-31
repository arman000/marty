require 'marty/postings/grid'

module Marty
  module Postings
    class Window < Netzke::Window::Base
      def configure(c)
        super

        c.title = I18n.t('select_posting')
        c.modal = true
        c.items = [:posting_grid]
        c.lazy_loading = true
        c.width = 600
        c.height = 350
      end

      component :posting_grid do |c|
        c.klass = Marty::Postings::Grid
        c.rows_per_page = 12
        c.permissions = {
          update:           false,
          delete:    true, # hijacked for selection
          create:    false,
        }
        # c.bbar  = []
      end
    end
  end
end
