class Marty::ApiLogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: :admin,
                        update: :admin
  @@attrs = [
             :script,
             :node,
             :attrs,
             :input,
             :output,
             :error,
             :remote_ip,
             :auth_name,
             :start_time,
             :end_time,
            ]

  def configure(c)
    super
    c.editing = :in_form
    c.paging = :buffered
    c.title = 'Api Log View'
    c.model = Marty::Log
    c.attributes = @@attrs
    c.scope = {message_type: 'api'}
    c.store_config.merge!(sorters: [{property: :timestamp, direction: 'DESC'}])
  end

  component :edit_window do |c|
    super(c)
    c.width = 1200
  end

  def default_form_items
    [
      :script,
      :node,
      :attrs,
      :start_time,
      :end_time,
      textarea_field(:input).merge!({height: 300}),
      textarea_field(:output).merge!({height: 300}),
      :error,
      :remote_ip,
      :auth_name,
    ]
  end

  # FIXME: datetime of virtual attributes is not working due to netzke renderer?
  # workaround: leaving as string and filtering by LIKE
  @@attrs.each do |a|
    attribute a do |c|
      c.filterable = true
      c.read_only  = true
      c.sorting_scope = lambda {
        |r, dir|
        r.order("details->>'#{a.to_s}'" + dir.to_s)
      }
      c.filter_with = lambda {
        |r, v, op|
        r.where("details->>'#{a.to_s}' #{op} '#{v}%'")
      }
      case a
      when :start_time, :end_time
        c.getter = lambda {
          |r|
          r.send(a).to_datetime.strftime('%Y-%m-%d %H:%I:%S.%L')
        }
      when :input, :output
        c.getter = lambda { |r| r.send(a).pretty_inspect }
        c.width     = 900
        c.read_only = true
      end
    end
  end

  [:input, :output].each do |a|
    column a do |c|
      c.width  = 250
      c.getter = lambda { |r| r.send(a).to_json }
    end
  end
end
ApiLogView = Marty::ApiLogView
