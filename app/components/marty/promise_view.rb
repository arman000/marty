class Marty::PromiseView < Netzke::Tree::Base
  extend ::Marty::Permissions
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

  def class_can?(op)
    self.class.can_perform_action?(op)
  end

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
      :status,
      :cformat,
      :error,
    ]
    c.root_visible = false
    c.paging = :none
    c.bbar = bbar
    c.read_only = true
    c.permissions = {
      create: class_can?(:create),
      read:   class_can?(:read),
      update: class_can?(:update),
      delete: class_can?(:delete)
    }
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

  attribute :status do |config|
    config.hidden = true
  end

  attribute :cformat do |config|
    config.text = I18n.t('jobs.cformat')
    config.width = 90
  end

  attribute :error do |config|
    config.getter = ->(record) do
      @results[record.id] unless record.status
    end

    config.flex = 1
  end
end

PromiseView = Marty::PromiseView
