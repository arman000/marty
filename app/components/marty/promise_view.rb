class Marty::PromiseView < Marty::Tree
  has_marty_permissions read: :any

  client_styles do |config|
    config.require :promise_view
  end

  client_class do |c|
    c.job_path = l(<<-JS)
    function(jid) {
      return '#{Marty::Util.marty_path}/job/download?job_id=' + jid;
    }
    JS

    c.include :promise_view
  end

  ######################################################################

  def configure(c)
    super

    c.title = I18n.t('jobs.promise_view')
    c.model = 'Marty::VwPromise'
    c.attributes = [
      { name: :title, xtype: :treecolumn },
      :user__login,
      :job_id,
      :priority,
      :start_dt,
      :end_dt,
      :total_time,
      :status,
      :run_by,
      :cformat,
      :error,
      :timeout
    ]
    c.root_visible = false
    c.paging = :none
    c.bbar = bbar
    c.read_only = true
  end

  def bbar
    [:clear, :cancel_job, '->', :refresh, :download]
  end

  action :clear do |a|
    a.text     = a.tooltip = 'Clear'
    a.disabled = false
    a.icon_cls = 'fa fa-minus glyph'
    a.hidden   = !self.class.has_perm?(:admin)
  end

  action :cancel_job do |a|
    a.text     = a.tooltip = 'Cancel Job'
    a.disabled = false
    a.icon_cls = 'fa fa-minus glyph'
    a.hidden   = !self.class.has_perm?(:admin)
  end

  action :download do |a|
    a.text     = a.tooltip = 'Download'
    a.disabled = true
    a.icon_cls = 'fa fa-download glyph'
  end

  action :refresh do |a|
    a.text     = a.tooltip = 'Refresh'
    a.disabled = false
    a.icon_cls = 'fa fa-sync-alt glyph'
  end

  endpoint :clear do |_params|
    Marty::Promise.cleanup(true)
    client.netzke_on_refresh
  end

  endpoint :cancel_job do |id|
    Marty::Promises::Cancel.call(id)
    client.netzke_on_refresh
  end

  def get_records(params)
    search_scope = config[:live_search_scope] || :live_search
    res = Marty::VwPromise.children_for_id(params[:id], params[search_scope])

    # Fetch actual promise objects without results in advance to avoid N+1
    promises_without_status_ids = res.reject(&:status).map(&:id)
    promises_without_status = Marty::Promise.where(
      id: promises_without_status_ids
    )

    @results = promises_without_status.each_with_object({}) do |promise, hash|
      hash[promise.id] = promise.result.to_s
    end

    res
  end

  attribute :title do |config|
    config.text = I18n.t('jobs.title')
    config.width = 300
  end

  attribute :user__login do |config|
    config.text = I18n.t('jobs.user_login')
    config.width = 100
  end

  attribute :priority do |config|
    config.width = 90
  end

  attribute :job_id do |config|
    config.width = 90
  end

  attribute :start_dt do |config|
    config.text = I18n.t('jobs.start_dt')
  end

  attribute :end_dt do |config|
    config.text = I18n.t('jobs.end_dt')
  end

  attribute :total_time do |config|
    config.text = I18n.t('jobs.total_time')
    config.width = 90

    config.getter = ->(record) do
      next unless record.start_dt
      next unless record.end_dt

      time_diff = record.end_dt - record.start_dt
      Time.zone.at(time_diff.to_i.abs).utc.strftime '%H:%M:%S'
    end
  end

  attribute :status do |config|
    config.hidden = true
  end

  attribute :cformat do |config|
    config.text = I18n.t('jobs.cformat')
    config.width = 90
  end

  attribute :error do |config|
    config.getter = ->(record) do
      next if record.status
      next @results[record.id] if @records

      Marty::Promise.find(record.id).result.to_s
    end

    editor_config = {
      xtype: :textarea,
    }

    config.field_config = editor_config
  end
end

Marty::PromiseView
