class Marty::ScheduleJobsLogs < Marty::Grid
  ACCESSIBLE_BY = [:admin]

  has_marty_permissions(
    read: ACCESSIBLE_BY,
    create: ACCESSIBLE_BY,
    update: ACCESSIBLE_BY,
    delete: ACCESSIBLE_BY,
    destroy: ACCESSIBLE_BY,
    destroy_all: ACCESSIBLE_BY,
    ignore: ACCESSIBLE_BY,
    edit_window__edit_form__submit: ACCESSIBLE_BY,
    add_window__add_form__submit: ACCESSIBLE_BY
  )

  def configure(c)
    super

    c.title ||= I18n.t('schedule_jobs_dashboard_view_title', default: "Scheduled Job's Logs")
    c.model = 'Marty::BackgroundJob::Log'
    c.paging = :buffered
    c.editing = :in_form
    c.multi_select = true

    c.attributes = [
      :job_class,
      :status,
      :error,
      :created_at
    ]

    c.store_config.merge!(sorters: [{ property: :id, direction: 'DESC' }])
  end

  def default_context_menu
    []
  end

  def default_bbar
    [:delete, :destroy_all, :ignore]
  end

  attribute :job_class do |c|
    c.width = 400
    c.read_only = true
  end

  attribute :status do |c|
    c.read_only = true
  end

  attribute :error do |c|
    c.width = 800
    c.read_only = true
    c.getter = ->(record) { record.error.to_json }
  end

  action :destroy_all do |a|
    a.text     = 'Delete all'
    a.tooltip  = 'Delete all logs'
    a.icon_cls = 'fa fa-trash glyph'
  end

  action :ignore do |a|
    a.text     = 'Ignore in diag'
    a.tooltip  = 'Ignore in diag'
    a.icon_cls = 'fa fa-trash glyph'
  end

  endpoint :destroy_all do
    Marty::BackgroundJob::Log.delete_all
    client.reload
  end

  endpoint :ignore do |ids|
    Marty::BackgroundJob::Log.
      where(id: ids).
      where(status: :failure).
      each { |record| record.update(status: :failure_ignore) }

    client.reload
  end
end

ScheduleJobsLogs = Marty::ScheduleJobsLogs
