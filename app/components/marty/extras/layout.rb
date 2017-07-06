module Marty; module Extras
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

  def enum_array(c, klass)
    editor_config = {
      multi_select: true,
      store:        klass::VALUES.to_a.sort,
      type:         :string,
      xtype:        :combo,
    }
    c.merge!(
      type:          :string,
      column_config: { editor: editor_config },
      field_config:  editor_config,
    )
  end

  def enum_setter(name)
    lambda {|r, v| r.send("#{name}=", v.nil? || v.empty? || v == '---' ?
                                        nil : v)}
  end

  ######################################################################
  # employ lots of hakery to implement NULLable boolean field in
  # Netzke 8.x.

  BOOL_MAP = {
    nil   => "---",
    true  => "True",
    false => "False",
  }

  MAP_BOOL = {
    "---"   => nil,
    ""      => nil,
    "True"  => true,
    "False" => false,
  }

  def bool_getter(name)
    lambda {|r| BOOL_MAP[r.send(name)]}
  end

  def bool_setter(name)
    lambda {|r, v| r.send("#{name}=", MAP_BOOL[v])}
  end

  def nullable_bool_column(name)
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          ["True", "False", "---"],
    }
    {
      column_config: { editor: editor_config },
      field_config:  editor_config,
      type:          :string,
      getter:        bool_getter(name),
      setter:        bool_setter(name),
    }
  end

  ######################################################################
  # make sure to validate range vals on the model (e.g. see rule.rb)

  def range_getter(name)
    lambda { |r|
      Marty::Util.pg_range_to_human(r.send(name))
    }
  end

  def range_setter(name)
    lambda do |r, v|
      r.send("#{name}=", v && (Marty::Util.human_to_pg_range(v) rescue v))
    end
  end

  def range_field(name)
    {
      name:   name,
      getter: range_getter(name),
      setter: range_setter(name),
    }
  end

  def range_column(c, name)
    c.getter = range_getter(name)
    c.setter = range_setter(name)
    c.width  = 80
    c.align  = 'right'
  end

end; end; end
