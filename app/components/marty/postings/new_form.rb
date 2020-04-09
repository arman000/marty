require 'marty/postings/summary_grid'

module Marty
  module Postings
    class NewForm < Marty::Form
      extend ::Marty::Permissions

      # override this to set permissions for posting types
      has_marty_permissions read: :any

      client_class do |c|
        c.include :new_form
      end

      action :apply do |a|
        a.text     = I18n.t('create_posting')
        a.tooltip  = I18n.t('create_posting')
        a.icon_cls = 'fa fa-clock glyph'
      end

      ######################################################################

      endpoint :submit do |params|
        res = super(params)
        client.close_me
        res
      end

      def configure(c)
        super

        c.model = 'Marty::Posting'
        c.items = [
          :posting_type,
          :comment,
          :summary_grid
        ]
      end

      attribute :posting_type do |c|
        store = Marty::Postings::NewForm.can_perform_actions

        c.editor_config = {
          multi_select: false,
          store:        store,
          type:         :string,
          xtype:        :combo,
        }
      end

      component :summary_grid do |c|
        c.klass = Marty::Postings::SummaryGrid
        c.data_store = { auto_load: false }
        c.selected_posting_type = client_config[:selected_posting_type]
      end
    end
  end
end
