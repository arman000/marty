class Marty::ScheduleJobsDashboard < Marty::Grid
  ACCESSIBLE_BY = [:admin]

  has_marty_permissions(
    read: ACCESSIBLE_BY,
    create: ACCESSIBLE_BY,
    update: ACCESSIBLE_BY,
    delete: ACCESSIBLE_BY,
    destroy: ACCESSIBLE_BY,
    edit_window__edit_form__submit: ACCESSIBLE_BY,
    add_window__add_form__submit: ACCESSIBLE_BY,
    reschedule: ACCESSIBLE_BY
  )

  def configure(c)
    super

    c.title ||= I18n.t('schedule_jobs_dashboard_view_title', default: 'Schedule Jobs Dashboard')
    c.model = 'Marty::BackgroundJob::Schedule'
    c.paging = :buffered
    c.editing = :in_form
    c.multi_select = false

    c.attributes = [
      :job_class,
      :cron,
      :state
    ]
  end

  def default_bbar
    super + [:reschedule]
  end

  def default_context_menu
    []
  end

  attribute :job_class do |c|
    c.width = 400
  end

  attribute :cron do |c|
    c.width = 400
  end

  attribute :state do |c|
    c.width = 150
    editor_config = {
      trigger_action: :all,
      xtype: :combo,
      store: Marty::BackgroundJob::Schedule::ALL_STATES,
      forceSelection: true,
    }

    c.column_config = { editor: editor_config }
    c.field_config  = editor_config
  end

  endpoint :edit_window__edit_form__submit do |params|
    result = super(params)
    next result if result.empty?

    obj_hash = result.first
    Marty::BackgroundJob::UpdateSchedule.call(id: obj_hash['id'], job_class: obj_hash['job_class'])

    result
  end

  endpoint :add_window__add_form__submit do |params|
    result = super(params)
    next result if result.empty?

    obj_hash = result.first
    Marty::BackgroundJob::UpdateSchedule.call(id: obj_hash['id'], job_class: obj_hash['job_class'])

    result
  end

  endpoint :multiedit_window__multiedit_form__submit do |_params|
    client.netzke_notify 'Multiediting is disabled for cron schedules'
  end

  endpoint :destroy do |params|
    res = params.each_with_object({}) do |id, hash|
      job_class = model.find_by(id: id)&.job_class
      result = super([id])

      # Do nothing If it wasn't destroyed
      next hash.merge(result) unless result[id.to_i] == 'ok'

      Marty::BackgroundJob::UpdateSchedule.call(id: id, job_class: job_class)
      hash.merge(result)
    end

    res
  end

  action :reschedule do |a|
    a.text     = 'Reschedule'
    a.icon_cls = 'fa fa-redo glyph'
    a.handler  = :netzke_reschedule
  end

  endpoint :reschedule do
    result = system("RAILS_ENV=#{Rails.env} rake marty:jobs:schedule")
    client.netzke_notify result ? 'Jobs scheduled' : 'Scheduling failed'
  end
end

ScheduleJobsDashboard = Marty::ScheduleJobsDashboard
