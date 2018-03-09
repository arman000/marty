class Marty::BaseRuleView < Marty::McflyGridPanel
  include Marty::Extras::Layout

  def self.klass
    Marty::BaseRule
  end
  def klass
    self.class.klass
  end

  def self.base_fields
    [:name]
  end
  def self.computed_fields
    [:computed_guards, :grids, :results]
  end
  def configure(c)
    super
    c.model = self.class.klass
    c.title = I18n.t('rule')
    c.attributes = self.class.base_fields +
                   klass.guard_info.
                     sort_by{|_, h| h[:order] || 0}.
                     reject{|_, h| h[:hidden]}.
                     map { |name, _| name.to_sym } + self.class.computed_fields
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

  class DupKeyError < StandardError
    def initialize(key, lineno)
      @key    = key
      @lineno = lineno
    end
    def message
      "keyword '#{@key}' specified more than once (line #{@lineno})"
    end
  end

  def self.simple_to_hashstr(s)
    pairs = []
    keys = Set.new
    s.lines.each.with_index(1) do |line, idx|
      next if /\A\s*\z/.match(line)
      line.chomp!
      begin
        m = /\A\s*([a-z0-9][a-z0-9_]*)\s*=\s*(.*)\s*\z/.match(line)
        k, v = m[1], m[2]
        v = [v].to_json[1..-2]
        raise DupKeyError.new(k, idx) if keys.include?(k)
        raise unless /\A['"].*['"]\z/.match(v)
        keys << k
      rescue DupKeyError => e
        raise
      rescue => e
        raise "syntax error on line #{idx}"
      end
      pairs << [k, v]
    end

    kvs = pairs.map { |k, v| %Q("#{k}":#{v}) }.join(",")
    "{#{kvs}}"
  end

  def self.hash_to_simple(h)
    return unless h && h.present?
    fmt = '%-' +  h.keys.map(&:length).max.to_s + 's = %s'
    h.map do |k, vstr|
      fmt % [k, vstr]
    end.join("\n") || ''
  end

  def jsonb_getter(c)
    lambda { |r| md = r.send(c); md.present? && md.to_json || '' }
  end

  def jsonb_simple_getter(c)
    lambda {|r| Marty::BaseRuleView.hash_to_simple(r.send(c)) }
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

  def self.jsonb_field_getter(j, c, nullbool=nil)
    lambda do |r|
      rv = r.send(j)[c]
      v = nullbool ? (rv == true ? 'True' :
                        rv == false ? 'False' : rv) : rv
      v || ""
    end
  end

  def self.jsonb_field_setter(j, c, bool=nil)
    lambda do |r, rv|
      v = bool ? rv.to_s.downcase == 'true' : rv
      rv == '' || rv == '---' ? r.send(j).delete(c) : r.send(j)[c] = v
    end
  end

  def json_sort_scope(c)
    lambda { |r, dir| r.order("#{c}::text " + dir.to_s) }
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

  def self.grid_column(c, label=nil)
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          Marty::DataGrid.where(obsoleted_dt: 'infinity').
        pluck(:name) + ['---'],
      forceSelection: true,
    }
    {
      name: label || c,
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
    self.class.base_fields
  end

  def form_items_guards
    klass.guard_info.reject{|_, h| h[:hidden]}.keys.map{|x|x.to_sym}
  end

  def form_items_grids
    [jsonb_field(:grids,
                 getter: jsonb_simple_getter(:grids),
                 setter: jsonb_simple_setter(:grids),
                 height: 75)]
  end

  def form_items_computed_guards
    [jsonb_field(:computed_guards,
                 getter: jsonb_simple_getter(:computed_guards),
                 setter: jsonb_simple_setter(:computed_guards),
                 height: 150)]
  end

  def form_items_results
    [jsonb_field(:results,
                 getter: jsonb_simple_getter(:results),
                 setter: jsonb_simple_setter(:results),
                 height: 150)]
  end

  def default_form_items
    [
      hbox(
        vbox(*form_items_attrs +
             form_items_guards,
             border: false,
             width: "40%",
        ),
        vbox(width: '2%', border: false),
        vbox(
             width: '55%', border: false),
        height: '40%',
        border: false,
      ),
      hbox(
        vbox(*form_items_computed_guards +
             form_items_grids +
             form_items_results,
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
    nullbool = h[:type] == :boolean && (h[:null] == true || !h.include?(:null))
    attribute name do |c|
      c.width = h[:width] || 150
      case
      when h[:type] == :datetime
        c.format = 'Y-m-d H:i'
      when h[:type] == :date
        c.format = 'Y-m-d'
      when nullbool
          c.type = :string
          enum_column(c, ['True', 'False'])
      else
        c.type = h[:type] || :string
      end
      c.label = h[:label] if h[:label]
      if h[:enum] || (h[:type] == :string && h[:values].present?)
        vals = h[:enum] || h[:values]
        if h[:multi]
          enum_array(c, vals)
        else
          enum_column(c, vals)
        end
      end
      # for some unexplained reason the getter/setter need the full
      # class qualification
      if h[:type] != :range
        c.getter = Marty::BaseRuleView.jsonb_field_getter(meth, namestr, nullbool)
        c.setter = Marty::BaseRuleView.jsonb_field_setter(meth, namestr,
                                                          h[:type]==:boolean)
        c.filter_with = lambda do |rel, value, op|
          v = ActiveRecord::Base.connection.quote(value)[1..-2]
          rel.where("#{meth}->>'#{namestr}' like '%#{v}%'")
        end
      else
        c.getter = range_getter(namestr, meth)
        c.setter = range_setter(namestr, meth)
        c.filterable = false
      end
      c.sorting_scope = get_json_sorter(meth, namestr)
    end
  end

  attribute :start_dt do |c|
    c.width = 100
    c.format = 'Y-m-d H:i'
  end

  attribute :end_dt do |c|
    c.width = 100
    c.format = 'Y-m-d H:i'
  end

  attribute :rule_type do |c|
    c.width = 200
  end

  def self.init_fields
    klass.guard_info.each do |namestr, h|
      field_maker(namestr, h, :simple_guards)
    end
  end

  computed_fields.each do |a|
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
