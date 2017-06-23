class Marty::EventView < Marty::Grid
  has_marty_permissions \
  read: :any,
  update: [:admin],
  delete: [:admin]

  def configure(c)
    super

    c.title ||= I18n.t('events', default: "Events")
    c.model                  = "Marty::Event"
    c.paging                 = :buffered
    c.editing                = :in_form
    c.attributes             = [
      :id,
      :klass,
      :subject_id,
      :enum_event_operation,
      :start_dt,
      :end_dt,
      :expire_secs,
      :promise_job_id,
      :promise_start_dt,
      :promise_end_dt,
      :promise_status,
      :error,
      :comment,
    ]

    c.store_config.merge!({sorters: [{property: :id,
                                 direction: 'DESC',
                                     }]})
    Marty::Event.cleanup
  end

  action :delete do |a|
    super(a)
    a.icon     = :user_delete
  end

  def default_context_menu
    []
  end

  attribute :klass do |c|
    c.text     = I18n.t("event_grid.klass")
    c.width = 100
    c.read_only = true
  end

  attribute :subject_id do |c|
    c.text     = I18n.t("event_grid.subject_id")
    c.width = 50
    c.read_only = true
  end

  attribute :enum_event_operation do |c|
    c.text     = I18n.t("event_grid.enum_event_operation")
    c.width = 100
    c.read_only = true
  end

  attribute :start_dt_dt do |c|
    c.text     = I18n.t("event_grid.start_dt")
    c.format    = "Y-m-d H:i:s"
  end

  attribute :end_dt_dt do |c|
    c.text     = I18n.t("event_grid.end_dt")
    c.format    = "Y-m-d H:i:s"
  end

  attribute :error do |c|
    error_map = {
      nil   => "",
      true  => "Error",
      false => "Success",
    }
    map_error = error_map.each_with_object({}) { |(k, v), h| h[v] = k }
    editor_config = {
      trigger_action: :all,
      xtype:          :combo,
      store:          ["Success", "Error", ""],
    }
    c.column_config = { editor: editor_config }
    c.field_config  = editor_config
    c.text   = I18n.t("event_grid.error")
    c.type   = :string
    c.width  = 150
    c.getter = lambda {|r| error_map[r.error]}
    c.setter = lambda {|r, v| r.error = map_error[v]}
  end

  attribute :comment do |c|
    c.text     = I18n.t("event_grid.comment")
    c.width = 400
  end

  def promise_getter(field)
    lambda { |r|
      return nil unless r.promise_id
      return nil unless p = Marty::Promise.where(id: r.promise_id).first
      p.send(field)
    }
  end
  attribute :promise_job_id do |c|
    c.text     = I18n.t("event_grid.promise_job_id")
    c.getter = promise_getter(:job_id)
    c.read_only = true
  end

  attribute :promise_start_dt do |c|
    c.text     = I18n.t("event_grid.promise_start_dt")
    c.width = 150
    c.getter = promise_getter(:start_dt)
    c.read_only = true
  end

  attribute :promise_end_dt do |c|
    c.text     = I18n.t("event_grid.promise_end_dt")
    c.width = 150
    c.getter = promise_getter(:end_dt)
    c.read_only = true
  end

  attribute :promise_status do |c|
    c.text     = I18n.t("event_grid.promise_status")
    c.getter = promise_getter(:status)
    c.read_only = true
  end

end

EventView = Marty::EventView
