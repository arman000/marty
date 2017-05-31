class Marty::ApiLogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: :admin,
                        update: :admin

  def configure(c)
    super
    c.editing = :in_form
    c.paging = :buffered
    c.title = 'Api Log View'
    c.model = Marty::ApiLog
    c.attributes = [
      :script,
      :node,
      :attrs,
      :start_time,
      :end_time,
      :input,
      :output,
      :error,
      :remote_ip,
      :auth_name,
    ]

    c.store_config.merge!(
      {sorters: [{ property: :start_time, direction: :desc }]},
    )
  end

  component :edit_window do |c|
    super(c)
    c.width = 1200
  end

  [:script, :node, :attrs, :remote_ip, :auth_name, :start_time,
   :end_time].each do |a|
    attribute a do |c|
      c.read_only = true
    end
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

  [:input, :output].each do |a|
    attribute a do |c|
      c.text = a.to_s
      c.width     = 900
      c.read_only = true
      c.type = :string
      c.getter = lambda { |r| r.send(a).pretty_inspect }
    end
    column a do |c|
      c.width = 250
      c.type = :string
      c.getter = lambda { |r| r.send(a).to_json }
    end
  end

end
ApiLogView = Marty::ApiLogView
