class Marty::LogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: [:admin],
                        update: [:admin]

  def configure(c)
    super

    c.title ||= I18n.t('log_viewer', default: "Log Viewer")
    c.model      = "Marty::Log"
    c.paging     = :pagination
    c.editing    = :in_form
    c.attributes = [
      :timestamp_custom,
      :message_type,
      :message,
      :details
    ]

    c.store_config.merge!(sorters: [{property: :timestamp, direction: 'DESC'}])
  end

  def default_context_menu
    []
  end

  def default_form_items
    [
      :timestamp_custom,
      :message_type,
      :message,
      textarea_field(:details).merge!({height: 400})
    ]
  end

  component :edit_window do |c|
    super(c)
    c.width = 1200
  end

  attribute :message_type do |c|
    c.text         = I18n.t("log_grid.message_type")
    c.width        = 100
    c.read_only    = true
  end

  attribute :message do |c|
    c.text         = I18n.t("log_grid.message")
    c.width        = 400
    c.read_only    = true
  end

  # FIXME?: timestamp_custom is needed to display datetime data proprely
  # UI does not interact well with AR/PG and doesn't display fractional s
  # This work around requires explicit sorting/filtering
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
    c.sorting_scope = lambda {|r, dir| r.order("timestamp " + dir.to_s)}

    # FIXME?: The UI AR/PG DateTime workaround requires the timestamp to be cast
    # to text in order to compare filter input using the LIKE operator.
    # Otherwise it will fail. '<' and '>' functionality is missing.
    c.filter_with = lambda {|r, v, op|
      r.where("timestamp::text  #{op} '#{v}%'")}
  end

  column :details do |c|
    c.getter = lambda { |r| CGI.escapeHTML(r.details.pretty_inspect) }
    c.filter_with = lambda {|r, v, op|
      r.where("details::text  #{op} '%#{v}%'")}
  end

  attribute :details do |c|
    c.text      = I18n.t("log_grid.details")
    c.width     = 900
    c.read_only = true
    c.getter    = lambda { |r| r.details.pretty_inspect}
  end
end

LogView = Marty::LogView
