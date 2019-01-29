class Marty::ApiLogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: :admin,
                        update: :admin

  DATE_OP_MAP = {
    'eq' => '=',
    'gt' => '>',
    'lt' => '<'
  }

  @@attrs = [
    :timestamp_custom,
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
    c.editing    = :in_form
    c.paging     = :pagination
    c.title      = 'Api Log View'
    c.model      = Marty::Log
    c.attributes = @@attrs
    c.scope      = { message_type: 'api' }
    c.store_config.merge!(sorters: [{ property: :timestamp, direction: 'DESC' }])
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
      textarea_field(:input).merge!({ height: 300 }),
      textarea_field(:output).merge!({ height: 300 }),
      :error,
      :remote_ip,
      :auth_name,
    ]
  end

  @@attrs.each do |a|
    attribute a do |c|
      c.filterable    = true
      c.read_only     = true
      c.getter        = lambda { |r| r.details[a.to_s] }
      c.sorting_scope = lambda { |r, dir|
        r.order("details->>'#{a.to_s}'" + dir.to_s)
      }
      c.filter_with = lambda { |r, v, op|
        r.where("details->>'#{a.to_s}' #{op} '#{v}%'")
      } unless [:start_time, :endtime].include?(a)

      case a
      when :start_time, :end_time
        c.type        = :datetime
        c.format      = 'Y-m-d h:i:s'
        c.getter      = lambda { |r| Time.zone.parse(r.details[a.to_s]) }
        c.filter_with = lambda { |r, v, op|
          r.where("(details->>'#{a.to_s}')::date #{DATE_OP_MAP[op]} '#{v}%'")
        }
      when :input, :output
        c.getter    = lambda { |r| r.details[a.to_s].pretty_inspect }
        c.width     = 900
        c.read_only = true
        c.filter_with = lambda { |r, v, op|
          r.where("(details->>'#{a.to_s}')::text #{op} '%#{v}%'")
        }
      end
    end
  end

  [:input, :output].each do |a|
    column a do |c|
      c.width  = 250
      c.getter = lambda { |r| r.details[a.to_s].to_json }
    end
  end

  #copied from log_view.rb
  attribute :timestamp_custom do |c|
    c.text         = I18n.t("log_grid.timestamp")
    c.width        = 200
    c.read_only    = true
    c.filterable = true
    c.xtype        = :datecolumn
    c.format       = 'Y-m-d h:i:s.u'
    c.field_config = {
      xtype: :displayfield,
    }
    c.getter = lambda { |r| Time.at(r.timestamp) }
    c.sorting_scope = lambda { |r, dir| r.order("timestamp " + dir.to_s) }

    # FIXME?: The UI AR/PG DateTime workaround requires the timestamp to be cast
    # to text in order to compare filter input using the LIKE operator.
    # Otherwise it will fail. '<' and '>' functionality is missing.
    c.filter_with = lambda { |r, v, op|
      r.where("timestamp::text  #{op} '#{v}%'")
    }
  end
end
ApiLogView = Marty::ApiLogView
