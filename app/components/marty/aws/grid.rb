class Marty::Aws::Grid < Marty::Grid
  include Marty::Extras::Layout

  has_marty_permissions create: :admin,
                        read:   :admin,
                        delete: :admin

  def self.aws_model client, type
    define_method :initialize do |args, kwargs|
      super(args, kwargs)
      client            = client.downcase
      @aws_client_class = "Marty::Aws::#{client.capitalize}".constantize
      @aws_client       = client
      @aws_object_type  = type.downcase
    end
  end

  def self.field_maker(namestr, h, meth, nested=[])
    name = namestr.to_sym
    nullbool = h[:type] == :boolean && (h[:null] == true || !h.include?(:null))
    attribute name do |c|
      c.hidden    = true if name == :aid
      c.read_only = true
      c.flex  = 1
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
      if h[:type] != :range
        c.getter = self.class.jsonb_field_getter(meth, namestr, nested, nullbool)
        nested_path = nested.map{|v| "->'#{v}'"}.join

        c.filter_with = lambda do |rel, value, op|
          v = ActiveRecord::Base.connection.quote(value)[1..-2]
          rel.where("#{meth}#{nested_path}->>'#{namestr}' like '%#{v}%'")
        end
      else
        c.getter     = range_getter(namestr, meth)
        c.filterable = false
      end
      c.sorting_scope = get_json_sorter(meth, namestr)
    end
  end

  def self.jsonb_field_getter(j, c, nested, nullbool=nil)
    lambda do |r|
      rv = r.send(j)
      nested.each{|k| rv = rv[k]}
      rv = rv.is_a?(Array) ? rv.detect{|h| h['name'] == c}.try(:[],'value') :
             rv.try(:[], c)

      v = nullbool ? (rv == true ? 'True' : rv == false ? 'False' : rv) : rv
      v || ""
    end
  end

  endpoint :get_objects do
    begin
      user = Marty::User.current

      return client.netzke_notify "No current user" unless user

      ActiveRecord::Base.transaction do
        pid        = client_config['parent_id']
        aws_client = @aws_client_class.new
        fn         = "get_#{@aws_object_type.pluralize}"

        aid        = Marty::Aws::Object.find(pid).aid if pid
        res        = aid ? aws_client.send(fn, aid) : aws_client.send(fn)

        processed = res.map do |s|
          s = s.to_h
          s[:aid] = s[:id]
          s[:_attributes] = s[:attributes]
          s.except(:id, :attributes)
        end

        Marty::Aws::Object.where(
          marty_user_id:     user.id,
          client:      @aws_client,
          object_type: @aws_object_type,
        ).delete_all

        processed.each do |j|
          Marty::Aws::Object.create!(
            marty_user_id:      user.id,
            client:       @aws_client,
            object_type:  @aws_object_type,
            value:       j,
            created_dt: DateTime.now,
          )
        end
      end
    rescue => e
      client.netzke_notify e.message
    end
  end

  def configure(c)
    super
    c.paging  = :pagination
    c.editing = :in_form
    c.title   = "AWS Base"
    c.model   = "Marty::Aws::Object"
  end

  client_class do |c|
    c.init_component = l(<<-JS)
    function() {
      var me = this;
      me.callParent();
      me.getStore().on('beforeload', function(){me.server.getObjects()}, this);
    }
    JS

  end

  def get_records params
    model.where(marty_user_id: Marty::User.current.id,
                client: @aws_client,
                object_type: @aws_object_type).scoping do
      super
    end
  end

  component :view_window do |c|
    super c
    c.title = "AWS #{@aws_object_type.humanize.upcase} (locked)"
  end

  def default_bbar
    []
  end
end
