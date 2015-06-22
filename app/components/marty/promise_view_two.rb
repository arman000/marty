class Marty::PromiseViewTwo < Netzke::Basepack::Tree
  extend ::Marty::Permissions

  css_configure do |config|
    config.require :promise_view
  end

  js_configure do |config|
    config.default_get_row_class = <<-JS
    function(record, index, rowParams, ds) {
       var status = record.get('status');
       if (status === false) return "red-row";
       if (status === true)  return "green-row";
       return "orange-row";
    }
    JS

    config.listen_fn = <<-JS
    function(obj, search_text) {
        var lg = this.ownerCt.ownerCt;
        lg.getStore().getProxy().extraParams.live_search = search_text;
        lg.getStore().load();
    }
    JS

    # Live search box -- direct copy from Marty::LiveSearchGridPanel
    config.tbar = ['->', {
                name:  'live_search_text',
                xtype: 'textfield',
                enable_key_events: true,
                ref: '../live_search_field',
                empty_text: 'Search',
                listeners: {
                  change: {
                    fn: config.listen_fn,
                    buffer: 500,
                  }
                }
              }]
  end

  def configure(config)
    super
    config.title = I18n.t("jobs.promise_view")
    config.model = "Marty::Promise"
    config.columns = [
      {name: :title, xtype: :treecolumn},
      :user__login,
      :job_id,
      :start_dt,
      :end_dt,
      :status,
      :cformat,
      :error,
    ]
    config.root_visible = false
    config.enable_pagination = false
    config.bbar = bbar

    # garbage collect old promises (hacky to do this here)
    Marty::Promise.cleanup(false)
  end

  def bbar
    [:clear, '->', :refresh, :download]
  end

  js_configure do |config|
    config.init_component = <<-JS
    function() {
       this.callParent();
       this.getSelectionModel().on('selectionchange', function(selModel) {
          this.actions.download &&
          this.actions.download.setDisabled(!selModel.hasSelection());
       }, this);
       this.getView().getRowClass = this.defaultGetRowClass;
    }
    JS

    config.on_download = <<-JS
    function() {
       var jid = this.getSelectionModel().selected.first().getId();
       // FIXME: seems pretty hacky
       window.location = "#{Marty::Util.marty_path}/job/download?job_id=" + jid;
    }
    JS

    config.on_refresh = <<-JS
    function() {
       this.store.load();
    }
    JS

    config.on_clear = <<-JS
    function(params) {
       var me = this;
       Ext.Msg.show({
         title: 'Clear All Jobs',
         msg: 'Enter CLEAR and press OK to clear all previous jobs',
         width: 375,
         buttons: Ext.Msg.OKCANCEL,
         prompt: true,
         fn: function (btn, value) {
          (btn == "ok" && value == "CLEAR") && me.serverClear({});
         }
       });
    }
    JS
  end

  action :clear do |a|
    a.text     = a.tooltip = 'Clear'
    a.disabled = false
    a.icon     = :application_delete
    a.hidden   = !self.class.has_admin_perm?
  end

  action :download do |a|
    a.text     = a.tooltip = 'Download'
    a.disabled = true
    a.icon     = :application_put
  end

  action :refresh do |a|
    a.text     = a.tooltip = 'Refresh'
    a.disabled = false
    a.icon     = :arrow_refresh
  end

  endpoint :server_clear do |params, this|
    Marty::Promise.cleanup(true)
    this.on_refresh
  end

  def get_records params
    search_scope = config[:live_search_scope] || :live_search
    Marty::Promise.children_for_id(params[:id], params[search_scope])
  end

  column :title do |config|
    config.text = I18n.t('jobs.title')
    config.width = 300
  end

  column :user__login do |config|
    config.text = I18n.t('jobs.user_login')
    config.width = 100
  end

  column :job_id do |config|
    config.width = 90
  end
  
  column :start_dt do |config|
    config.text = I18n.t('jobs.start_dt')
  end

  column :end_dt do |config|
    config.text = I18n.t('jobs.end_dt')
  end

  column :status do |config|
    config.hidden = true
  end

  column :cformat do |config|
    config.text = I18n.t('jobs.cformat')
    config.width = 90
  end

  column :error do |config|
    config.getter = ->(record) { record.result.to_s if record.status == false }
    config.flex = 1
  end
end

PromiseViewTwo = Marty::PromiseViewTwo
