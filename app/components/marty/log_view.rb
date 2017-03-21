class Marty::LogView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions read: [:admin],
                        update: [:admin]

  def configure(c)
    super

    c.title    ||= I18n.t('log_viewer', default: "Log Viewer")
    c.model      = "Marty::Log"
    c.paging     = :buffered
    c.editing    = :in_form
    c.attributes = [
      :timestamp,
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
      :timestamp,
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

  attribute :timestamp do |c|
    c.text         = I18n.t("log_grid.timestamp")
    c.width        = 200
    c.read_only    = true
    c.xtype        = :datecolumn
    c.format       = 'Y-m-d h:i:s.u'
    c.field_config = {
      xtype: :displayfield,
    }
    c.getter = lambda { |r| Time.at(r.timestamp) }
  end

  column :details do |c|
    c.getter = lambda { |r| CGI.escapeHTML(r.details) }
  end

  attribute :details do |c|
    c.text      = I18n.t("log_grid.details")
    c.width     = 900
    c.read_only = true
  end
end

LogView = Marty::LogView
