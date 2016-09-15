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

      def textarea_field(name, options={})
        {
          name:        name,
          width:       "100%",
          height:      150,
          xtype:       :textareafield,
          auto_scroll: true,
          spellcheck:  false,
          field_style: {
            font_family: 'courier new',
            font_size:   '12px'
          },
        } + options
      end

      ######################################################################
      # PG ENUM field handling

      def enum_column(c, klass)
        editor_config = {
          trigger_action: :all,
          xtype:          :combo,

          # hacky: extjs has issues with forceSelection true and clearing combos
          store:          klass::VALUES + ['---'],
          forceSelection: true,
        }
        c.merge!(
          column_config: { editor: editor_config },
          field_config:  editor_config,
          type:          :string,
          setter:        enum_setter(c.name),
        )
      end

      def enum_setter(name)
        lambda {|r, v| r.send("#{name}=", v == '---' || v.empty? ? nil : v)}
      end
    end
  end
end
