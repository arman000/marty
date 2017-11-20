class Marty::BaseRuleView < Marty::McflyGridPanel
  include Marty::Extras::Layout

  def self.klass
    Marty::Rule
  end
  def klass
    self.class.klass
  end

  FIELDS = [:computed_guards, :grids, :simple_results, :computed_results]
  def configure(c)
    super
    c.model = self.class.klass
    c.title = I18n.t('rule')
    c.attributes = [:name] + (klass.attr_info + klass.guard_info).
                             reject{|_, h| h[:hidden]}.
                             map { |name, _| name.to_sym } + FIELDS
    c.store_config.merge!(sorters: [{property: :name, direction: 'ASC'}])
    c.editing      = :in_form
    c.paging       = :pagination
    c.multi_select = false
  end

  def default_bbar
    super + [:dup_in_form]
  end

  def default_context_menu
    []
  end

  def jsonb_getter(c)
    lambda { |r| md = r.send(c); md.present? && md.to_json || '' }
  end

  def jsonb_simple_getter(c, unquoted=false)
    lambda {|r| Marty::BaseRule.hash_to_simple(r.send(c), unquoted) }
  end

  def jsonb_simple_setter(c, unquoted=false)
    msg = "#{c}="
    lambda { |r, v|
      return r.send(msg, nil) if v.blank?

      begin
        v = ActiveSupport::JSON.decode(
          Marty::BaseRule.simple_to_hashstr(v, unquoted))
      rescue => e
        v = { "~~ERROR~~": e.message }
      end
      r.send(msg, v)
    }
  end

  def self.jsonb_field_getter(j, c)
    lambda { |r| r.send(j)[c]||"" }
  end

  def self.jsonb_field_setter(j, c)
    lambda do |r, v|
      v.blank? ||  v == '---' ? r.send(j).delete(c) : r.send(j)[c] = v
    end
  end

  def json_sort_scope(c)
    lambda { |r, dir| r.order("#{c}::text " + dir.to_s) }
  end

  def default_form_items
   [:name, :attrs, :computed_guards, :grids, :simple_results,:computed_results]
  end

  component :add_window do |c|
    super(c)
    c.width = 1500
    c.height = 740
  end

  component :edit_window do |c|
    super(c)
    c.width = 1500
    c.height = 740
  end

  attribute :name do |c|
    c.width = 150
  end

  def self.grid_column(c)
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          Marty::DataGrid.where(obsoleted_dt: 'infinity').
        pluck(:name) + ['---'],
      forceSelection: true,
    }
    {
      name: c,
      width: 200,
      column_config: { editor: editor_config },
      field_config:  editor_config,
      type:          :string,
      getter: jsonb_field_getter(:grids, c.to_s),
      setter: jsonb_field_setter(:grids, c.to_s),
#      getter: lambda { |r| r.grids[c.to_s] },
#      setter: lambda { |r, v| r.grids[c.to_s] = v },
    }
  end

  def form_items_attrs
    klass.attr_info.reject{|_, h| h[:hidden]}.keys.map{|x|x.to_sym}
  end

  def form_items_guards
    klass.guard_info.reject{|_, h| h[:hidden]}.keys.map{|x|x.to_sym}
  end

  def form_items_simple_results
    [jsonb_field(:simple_results,
                 getter: jsonb_simple_getter(:simple_results, false),
                 setter: jsonb_simple_setter(:simple_results, false),
                 height: 150)]
  end

  def form_items_grids
    [jsonb_field(:grids,
                 getter: jsonb_simple_getter(:grids, false),
                 setter: jsonb_simple_setter(:grids, false),
                 height: 75)]
  end

  def form_items_computed_guards
    [jsonb_field(:computed_guards,
                 getter: jsonb_simple_getter(:computed_guards, true),
                 setter: jsonb_simple_setter(:computed_guards, true),
                 height: 150)]
  end

  def form_items_computed_results
    [jsonb_field(:computed_results,
                 getter: jsonb_simple_getter(:computed_results, true),
                 setter: jsonb_simple_setter(:computed_results, true),
                 height: 150)]
  end

  def default_form_items
    [
      hbox(
        vbox(*[:name] +
             form_items_attrs +
             form_items_guards,
             border: false,
             width: "40%",
        ),
        vbox(width: '2%', border: false),
        vbox(*form_items_simple_results,
             width: '55%', border: false),
        height: '40%',
        border: false,
      ),
      hbox(
        vbox(*form_items_computed_guards +
             form_items_grids +
             form_items_computed_results,
             width: '99%',
             border: false
        ),
        height: '40%',
       border: false
      )
    ]
  end

  def self.field_maker(namestr, h, meth)
    name = namestr.to_sym
    attribute name do |c|
      c.width = h[:width] || 150
      case h[:type]
      when :datetime; c.format = 'Y-m-d H:i'
      when :date; c.format = 'Y-m-d'
      else c.type = h[:type] || :string
      end
      c.label = h[:label] if h[:label]
      if h[:enum]
        if h[:multi]
          enum_array(c, h[:enum])
        else
          enum_column(c, h[:enum])
        end
      end
      # for some unexplained reason the getter/setter need the full
      # class qualification
      c.getter = Marty::BaseRuleView.jsonb_field_getter(meth, namestr)
      c.setter = Marty::BaseRuleView.jsonb_field_setter(meth, namestr)
      c.sorting_scope = get_json_sorter(meth, namestr)
      c.filter_with = lambda do |rel, value, op|
        v = ActiveRecord::Base.connection.quote(value)[1..-2]
        rel.where("#{meth}->>'#{namestr}' like '%#{v}%'")
      end

    end
  end

  def self.init_fields
    klass.attr_info.reject{|_,h|h[:hidden]}.each do |namestr, h|
      field_maker(namestr, h, :attrs)
    end

    klass.guard_info.each do |namestr, h|
      field_maker(namestr, h, :simple_guards)
    end
  end

  FIELDS.each do |a|
    column a do |c|
      c.flex   = 1
      c.getter = jsonb_getter(a.to_s)
      c.sorting_scope = json_sort_scope(a)
      c.filter_with = lambda do |rel, value, op|
        v = ActiveRecord::Base.connection.quote(value)[1..-2]
        rel.where("#{a}::text like '%#{v}%'")
      end
    end
  end
end
