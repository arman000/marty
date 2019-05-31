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
                     sort_by { |_, h| h[:order] || 0 }.
                     reject { |_, h| h[:hidden] }.
                     map { |name, _| name.to_sym } + self.class.computed_fields
    c.store_config.merge!(sorters: [{ property: :name, direction: 'ASC' }])
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

  # FSM to parse rule text into json
  def self.ruletext_to_hash(s)
    # states are
    #  :start   - before any attr is defined
    #  :in_attr - defining an attr
    #  :end     - end of input
    state = :start
    result = {}
    cur_attr = nil
    idx = 0
    input = s.lines

    # events are
    #  :attr    - starting with <identifier>\s*=
    #  :normal  - line not starting with ident =
    #  :end     - no more lines
    # get_event returns [event, data]
    get_event = lambda {
      line = input.try(&:shift)
      next [:end] unless line

      line.chomp!
      idx += 1
      m = /\A\s*([a-z][a-z0-9_]*)\s* = (.*)\z/.match(line)
      next [:attr, m[1..-1]] if m

      [:normal, line]
    }

    # start a new attribute
    # data is [ attr_name, everything after = ]
    new_attr = lambda { |data|
      cur_attr = data.shift
      raise DupKeyError.new(cur_attr, idx) if result[cur_attr]

      result[cur_attr] = data[0]
    }

    begin
      while state != :end
        event, extra = get_event.call
        case state
        when :start
          case event
          when :attr
            new_attr.call(extra)
            state = :in_attr
          when :normal
            raise
          when :end
            state = :end
          end
        when :in_attr
          case event
          when :attr
            new_attr.call(extra)
          when :normal
            result[cur_attr] += "\n" + extra
          when :end
            state = :end
          end
        end
      end
    rescue DupKeyError => e
      raise
    rescue StandardError => e
      raise "syntax error on line #{idx}"
    end
    result
  end

  def self.hash_to_ruletext(h)
    h.each_with_object('') do |(k, v), out|
      out << k + ' = ' + v + "\n"
    end
  end

  def jsonb_getter(c)
    lambda { |r| md = r.send(c); md.present? && md.to_json || '' }
  end

  def jsonb_simple_getter(c)
    lambda { |r| Marty::BaseRuleView.hash_to_ruletext(r.send(c)) }
  end

  def jsonb_simple_setter(c)
    msg = "#{c}="
    lambda { |r, v|
      return r.send(msg, nil) if v.blank?

      begin
        final = Marty::BaseRuleView.ruletext_to_hash(v)
      rescue StandardError => e
        final = { "~~ERROR~~": e.message }
      end

      # ActiveRecord ignores change in json key order
      r.send("#{c}_will_change!") if r[c.to_s].to_a != final.to_a

      r.send(msg, final)
    }
  end

  def self.jsonb_field_getter(j, c, nullbool = nil)
    lambda do |r|
      rv = r.send(j)[c]
      v = nullbool ? (rv == true ? 'True' :
                        rv == false ? 'False' : rv) : rv
      v || ''
    end
  end

  def self.jsonb_field_setter(j, c, bool = nil)
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

  component :view_window do |c|
    super(c)
    c.width = 1500
    c.height = 740
  end

  attribute :name do |c|
    c.width = 150
  end

  def self.grid_column(c, label = nil)
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
    klass.guard_info.reject { |_, h| h[:hidden] }.keys.map(&:to_sym)
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
                 height: 100)]
  end

  def form_items_results
    [jsonb_field(:results,
                 getter: jsonb_simple_getter(:results),
                 setter: jsonb_simple_setter(:results),
                 height: 225)]
  end

  def default_form_items
    [
      hbox(
        vbox(*form_items_attrs +
             form_items_guards,
             border: false,
             width: '40%',
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
      if h[:type] == :datetime
        c.format = 'Y-m-d H:i'
      elsif h[:type] == :date
        c.format = 'Y-m-d'
      elsif nullbool
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
                                                          h[:type] == :boolean)
        c.filter_with = lambda do |rel, value, _op|
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
      c.filter_with = lambda do |rel, value, _op|
        v = ActiveRecord::Base.connection.quote(value)[1..-2]
        rel.where("#{a}::text like '%#{v}%'")
      end
    end
  end
end
