class Marty::ReportExecutionView < Marty::Grid
  has_marty_permissions \
    create: [],
    read: :any,
    update: [],
    delete: [:admin],
    cleanup: [:admin]

  def configure(c)
    super

    c.title   = I18n.t('report_execution')
    c.model   = 'Marty::ReportExecution'
    c.attributes =
      [
        :created_at,
        :report,
        :user__login,
        :completed_at,
        :duration,
        :error,
      ]
    c.store_config.merge!(
      sorters: [{ property: :created_at, direction: 'DESC' }]
    )
  end

  def bbar
    super + [:cleanup]
  end

  attribute :user__login do |a|
    a.text = 'Run By'
  end

  attribute :duration do |a|
    a.text = 'Duration (s)'
    a.getter = lambda do |r|
      (r.completed_at - r.created_at).to_i.seconds if r.completed_at
    end
  end

  action :cleanup do |a|
    a.text     = a.tooltip = 'Clear'
    a.disabled = false
    a.icon_cls = 'fa fa-trash-alt'
    a.hidden   = !self.class.has_perm?(:admin)
  end

  endpoint :cleanup do |days_to_keep|
    begin
      model.cleanup(days_to_keep)
      client.netzke_notify('Cleanup done.')
    rescue StandardError => e
      Marty::Logger.error(e.message)
      client.netzke_notify('Cleanup failed.')
    ensure
      client.reload
    end
  end
end

ReportExecutionView = Marty::ReportExecutionView
