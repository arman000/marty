class Marty::ApiLogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: :admin,
                        update: :admin

  JSONB_DATE_OPS = {'gt' => '>',
                    'lt' => '<',
                    'eq' => '='}

  def configure(c)
    super
    c.editing = :in_form
    c.paging = :buffered
    c.title = 'Api Log View'
    c.model = Marty::Log
    c.attributes = [:script,
                    :node,
                    :attrs,
                    :input,
                    :output,
                    :error,
                    :remote_ip,
                    :auth_name,
                    :start_time,
                    :end_time]

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

  [:script,
   :node,
   :attrs,
   :input,
   :output,
   :error,
   :remote_ip,
   :auth_name,
  ].each do |a|
    attribute a do |c|
      c.filterable = true
      c.sorting_scope = lambda {
        |r, dir|
        r.order("details->>'#{a.to_s}'" + dir.to_s)
      }
      c.filter_with = lambda {
        |r, v, op|
        r.where("details->>'#{a.to_s}' #{op} '#{v}%'")
      }
    end
  end

  [:start_time, :end_time].each do |a|
    attribute a do |c|
      c.type = :date
      c.sorting_scope = lambda {
        |r, dir|
        r.order("details->>'#{a.to_s}'" + dir.to_s)
      }
      c.filter_with = lambda {
        |r, v, op|
        r.where("details->>'#{a.to_s}' #{JSONB_DATE_OPS[op]} '#{v}%'")
      }
    end
  end
end
ApiLogView = Marty::ApiLogView
