class Marty::PromiseView < Netzke::Tree::Base
  extend ::Marty::Permissions

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

  def configure(config)
    super
    config.title = I18n.t('jobs.promise_view')
    config.model = 'Marty::VwPromise'
    config.attributes = [
      { name: :title, xtype: :treecolumn },
      :user__login,
      :job_id,
      :start_dt,
      :end_dt,
      :status,
      :cformat,
      :error,
    ]
    config.root_visible = false
    config.paging = :none
    config.bbar = bbar
    config.read_only = true
    config.permissions = { update: false,
                           create: false,
                           delete: false,
                         }
    # garbage collect old promises (hacky to do this here)
    Marty::Promise.cleanup(false)
  end

  def bbar
    [:clear, '->', :refresh, :download]
  end

  action :clear do |a|
    a.text     = a.tooltip = 'Clear'
    a.disabled = false
    a.icon_cls = 'fa fa-minus glyph'
    a.hidden   = !self.class.has_admin_perm?
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

  endpoint :clear do |params|
    Marty::Promise.cleanup(true)
    client.netzke_on_refresh
  end

  def get_records params
    search_scope = config[:live_search_scope] || :live_search
    Marty::VwPromise.children_for_id(params[:id], params[search_scope])
  end

  attribute :title do |config|
    config.text = I18n.t('jobs.title')
    config.width = 300
  end

  attribute :user__login do |config|
    config.text = I18n.t('jobs.user_login')
    config.width = 100
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
    config.getter = ->(record) {
      if !record.status
        Marty::Promise.find_by(id: record.id).try(:result).to_s
      end
    }
    config.flex = 1
  end
end

PromiseView = Marty::PromiseView
