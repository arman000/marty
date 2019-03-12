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

  def dispfield(params = {})
    {
      attr_type: :displayfield,
      hide_label: !params[:field_label],
      read_only: true,
    }.merge(params)
  end

  def vspacer(params = {})
    vbox({ flex: 1, border: false }.merge(params))
  end

  def hspacer(params = {})
    hbox({ flex: 1, border: false }.merge(params))
  end

  def textarea_field(name, options = {})
    {
      name:        name,
      width:       '100%',
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

  def jsonb_field(name, options = {})
    {
        name:        name,
        width:       '100%',
        height:      150,
        xtype:       :textareafield,
        auto_scroll: true,
        spellcheck:  false,
        allow_blank: false,
        field_style: {
          font_family: 'courier new',
          font_size:   '12px'
        },
    }.merge(options)
  end

  def hash_to_simple(h)
    return unless h && h.present?
    fmt = '%-' +  h.keys.map(&:length).max.to_s + 's = %s'
    h.map do |k, vstr|
      fmt % [k, vstr]
    end.join("\n") || ''
  end

  def jsonb_simple_getter(c)
    lambda {|r| hash_to_simple(r.send(c)) }
  end

  def jsonb_simple_setter(c)
    msg = "#{c}="
    lambda { |r, v|
      return r.send(msg, nil) if v.blank?

      begin
        v = ActiveSupport::JSON.decode(
          Marty::BaseRuleView.simple_to_hashstr(v))
      rescue => e
        v = { "~~ERROR~~": e.message }
      end
      r.send(msg, v)
    }
  end

  ######################################################################
  # PG ENUM field handling

  def enum_column(c, class_or_array, col = nil)
    col ||= c.name.demodulize.tableize.singularize
    vals = class_or_array.is_a?(Array) ? class_or_array : class_or_array::VALUES
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,

      # hacky: extjs has issues with forceSelection true and clearing combos
      store:          vals + ['---'],

      # we can dynamically add enums (i.e. they're not in VALUES) --
      # turn off forced selection.
      # forceSelection: true,
    }
    c.merge!(
      column_config: { editor: editor_config },
      field_config:  editor_config,
      type:          :string,
      setter:        enum_setter(c.name),
      sorting_scope: get_sorter(col)
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
    lambda { |r, v| r.send("#{name}=", v.blank? || v == '---' ? nil : v) }
  end

  def get_sorter(col)
    lambda { |rel, dir| rel.order("#{col}::text #{dir.to_s}") }
  end

  ######################################################################
  # employ lots of hakery to implement NULLable boolean field in
  # Netzke 8.x.

  BOOL_MAP = {
    nil   => '---',
    true  => 'True',
    false => 'False',
  }

  MAP_BOOL = {
    '---'   => nil,
    ''      => nil,
    'True'  => true,
    'False' => false,
  }

  def bool_getter(name)
    lambda { |r| BOOL_MAP[r.send(name)] }
  end

  def bool_setter(name)
    lambda { |r, v| r.send("#{name}=", MAP_BOOL[v]) }
  end

  def nullable_bool_column(name)
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          ['True', 'False', '---'],
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

  def range_getter(name, json_field = nil)
    if json_field
      lambda { |r| Marty::Util.pg_range_to_human(r.send(json_field)[name]) }
    else
      lambda { |r| Marty::Util.pg_range_to_human(r.send(name)) }
    end
  end

  def range_setter(name, json_field = nil)
    if json_field
      lambda do |r, v|
        cookedv = v && v.present? && (Marty::Util.human_to_pg_range(v) rescue v)
        h = r.send(json_field)
        if cookedv
          r.send("#{json_field}=", h + { name => cookedv })
        else
          h.delete(name)
          r.send("#{json_field}=", h)
        end
      end
    else
      lambda do |r, v|
        r.send("#{name}=", v && (Marty::Util.human_to_pg_range(v) rescue v))
      end
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

  end;
module Columns
  def json_column a, opts={}
    column a do |c|
      c.flex = 1
      c.getter = lambda { |r| md = r.send(a); md.present? && md.to_json || '' }
      c.sorting_scope = lambda { |r, dir| r.order("#{a}::text " + dir.to_s) }
      c.filter_with = lambda do |rel, value, op|
        v = ActiveRecord::Base.connection.quote(value)[1..-2]
        rel.where("#{a}::text like '%#{v}%'") end

      # apply additional config options or overrides
      opts.each{|k,v| c.send("#{k}=", v)}
    end

  def tooltip s1, s2
    "<span data-qtip=\"#{s2}\">#{s1}</span>"
  end
end
end; end; end
