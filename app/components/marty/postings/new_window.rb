require 'marty/postings/new_form'

module Marty
  module Postings
    class NewWindow < Netzke::Window::Base
      def configure(c)
        super

        c.title        = I18n.t('new_posting')
        c.modal        = true
        c.items        = [:new_posting_form]
        c.lazy_loading = true
        c.width        = 800
        c.height       = 550
      end

      component :new_posting_form do |c|
        c.header = false
        c.klass = Marty::Postings::NewForm
      end
    end
  end
end
