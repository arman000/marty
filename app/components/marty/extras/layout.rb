module Marty
  module Extras
    module Layout
      
      def hbox(*args)
        params = args.pop
        params.merge(layout: { type: :hbox, align: :stretch },
                     items: args,
                     )
      end

      def vbox(*args)
        params = args.pop
        params.merge(layout: { type: :vbox, align: :stretch },
                     items: args,
                     )
      end

      def fieldset(title, *args)
        params = args.pop
        params.merge(items: args,
                     xtype: 'fieldset',
                     defaults: { anchor: '100%' },
                     title: title,
                     )
      end

      def dispfield(params={})
        {
          attr_type: :displayfield,
          hide_label: !params[:field_label],
          read_only: true,
        }.merge(params)
      end

      def vspacer(params={})
        vbox({flex: 1, border: false}.merge(params))
      end

      def hspacer(params={})
        hbox({flex: 1, border: false}.merge(params))
      end

    end
  end
end
