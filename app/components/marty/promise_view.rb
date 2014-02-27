class Marty::PromiseView < Marty::TreePanel
  css_configure do |c|
    c.require :promise_view
  end

  js_configure do |c|
    c.default_get_row_class = <<-JS
    function(record, index, rowParams, ds) {
       var status = record.get('status');
       if (status === false) return "red-row";
       if (status === true)  return "green-row";
       return "orange-row";
    }
    JS
  end

  def configure(c)
    c.title = I18n.t("jobs.promise_view")
    c.model = "Marty::Promise"
    c.columns = [
                 :parent,
                 :user__login,
                 :job_id,
                 :start_dt,
                 :end_dt,
                 :status,
                 :cformat,
                 :error,
                ]
    c.treecolumn = :parent
    super

    c.data_store.sorters = {
      property: "id",
      direction: 'DESC',
    }

    # garbage collect old promises (hacky to do this here)
    begin
      Marty::Promise.
        where('start_dt < ? AND parent_id IS NULL', Date.today-1).destroy_all
    rescue => exc
      Marty::Util.logger.error("promise GC error: #{exc}")
    end
  end

  def bbar
    [:status, '->', :refresh, :download]
  end

  js_configure do |c|
    c.init_component = <<-JS
    function() {
       this.callParent();
       this.getSelectionModel().on('selectionchange', function(selModel) {
          this.actions.download &&
          this.actions.download.setDisabled(!selModel.hasSelection());
       }, this);
    }
    JS

    c.on_download = <<-JS
    function() {
       var jid = this.getSelectionModel().selected.first().getId();
       // FIXME: seems pretty hacky
       window.location = "#{Marty::Util.marty_path}/job/download?job_id=" + jid;
    }
    JS

    c.on_refresh = <<-JS
    function() {
       this.store.load();
    }
    JS

    c.on_status = <<-JS
    function() {
       this.serverStatus();
    }
    JS

    c.show_detail = <<-JS
    function(details) {
       Ext.create('Ext.Window', {
         height: 	400,
         minWidth:	400,
         autoWidth: 	true,
         modal: 	true,
         autoScroll: 	true,
         html: 		details,
         title: 	"Details"
      }).show();
    }
    JS
  end

  action :download do |a|
    a.text	= a.tooltip = 'Download'
    a.disabled	= true
    a.icon	= :application_put
  end

  action :refresh do |a|
    a.text	= a.tooltip = 'Refresh'
    a.disabled	= false
    a.icon	= :arrow_refresh
  end

  action :status do |a|
    a.text	= 'Status'
    a.tooltip	= 'Run script/delayed_job status'
    a.disabled	= false
    a.icon	= :monitor
  end

  endpoint :server_status do |params, this|
    e, root = ENV['RAILS_ENV'], Rails.root
    p = "/usr/local/rvm/gems/ruby-1.9.3-p362/bin"
    # 2>&1 redirects STDERR to STDOUT since backticks only captures STDOUT
    cmd = "export RAILS_ENV=#{e};export PATH=#{p}:$PATH;" +
      "#{root}/script/delayed_job status 2>&1"
    status = `#{cmd}`
    html = status.html_safe.gsub("\n","<br/>")
    this.show_detail html
  end

  def get_children(params)
    params[:scope] = config[:scope]

    parent_id = params[:id]
    parent_id = nil if parent_id == 'root'

    scope_data_class(params) do
      data_class.where(parent_id: parent_id).scoping do
        data_adapter.get_records(params, final_columns)
      end
    end
  end

  column :parent do |c|
    c.text	= 'Job Name'
    c.getter 	= lambda { |r| r.title }
    c.width	= 275
  end

  column :status do |c|
    c.hidden = true
    # FIXME: TreePanel appears to not work with hidden boolean cols
    c.xtype = 'numbercolumn'
  end

  column :user__login do |c|
    c.text 	= I18n.t('jobs.user_login')
  end

  column :start_dt do |c|
    c.text 	= I18n.t('jobs.start_dt')
  end

  column :end_dt do |c|
    c.text 	= I18n.t('jobs.end_dt')
  end

  column :error do |c|
    c.getter = lambda {|r| r.result.to_s if r.status == false}
    c.flex = 1
  end

  column :cformat do |c|
    c.text = "Format"
  end

end

PromiseView = Marty::PromiseView
