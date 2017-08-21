require 'marty/scripting'
require 'marty/reporting'
require 'marty/posting_window'
require 'marty/new_posting_window'
require 'marty/import_type_view'
require 'marty/user_view'
require 'marty/event_view'
require 'marty/promise_view'
require 'marty/api_auth_view'
require 'marty/api_config_view'
require 'marty/api_log_view'
require 'marty/config_view'
require 'marty/data_grid_view'

class Marty::MainAuthApp < Marty::AuthApp
  extend ::Marty::Permissions

  # set of posting types user is allowed to post with
  def self.has_posting_perm?
    Marty::NewPostingForm.has_any_perm?
  end

  def self.has_scripting_perm?
    self.has_admin_perm?
  end

  def sep
    { xtype: 'tbseparator' }
  end

  def icon_hack(name)
    # There's a Netzke bug whereby, using an icon name in a hash
    # doesn't generate a proper URL.
    "#{Netzke::Core.ext_uri}/icons/#{name}.png"
  end

  def posting_menu
    {
      text:  warped ? "#{Marty::Util.get_posting.name}" : I18n.t("postings"),
      name:  "posting",
      tooltip: "Postings",
      icon:  icon_hack(:time),
      style: (warped ? "background-color: lightGrey;" : ""),
      menu:  [
        :new_posting,
        :select_posting,
        :select_now,
      ],
    }
  end

  def log_menu
    [
      {
        text: 'Log Maintenance',
        icon:  icon_hack(:wrench),
        disabled: !self.class.has_admin_perm?,
        menu: [
          :log_view,
          :log_cleanup,
        ]
      }
    ]
  end

  def api_menu
    [
      {
        text: 'API Management',
        icon:  icon_hack(:wrench),
        disabled: !self.class.has_admin_perm?,
        menu: [
          :api_auth_view,
          :api_config_view,
          :api_log_view,
        ]
      }
    ]
  end

  def system_menu
    {
      text:  I18n.t("system"),
      icon:  icon_hack(:wrench),
      style: "",
      menu:  [
        :import_type_view,
        :user_view,
        :config_view,
        :event_view,
        :reload_scripts,
        :load_seed,
      ] + background_jobs_menu + log_menu + api_menu
    }
  end

  def applications_menu
    {
      text: I18n.t("applications"),
      icon: icon_hack(:application_cascade),
      menu: [
        :data_grid_view,
        :reporting,
        :scripting,
        :promise_view,
      ],
    }
  end

  def background_jobs_menu
    [
      {
        text: 'Background Jobs',
        icon: icon_hack(:clock),
        disabled: !self.class.has_admin_perm?,
        menu: [
          :bg_status,
          :bg_stop,
          :bg_restart,
        ]
      },
    ]
  end

  def warped
    Marty::Util.warped?
  end

  def app_moniker
    warped ? 0x231B.chr('utf-8') : 0x03FB.chr('utf-8')
  end

  def app_title
    e = ENV['RAILS_ENV']

    title = "#{app_moniker} #{Rails.application.class.parent_name.titleize}"
    title += " - #{e.capitalize}" unless e == 'production'
    title += ' [TIME WARPED]' if warped
    title
  end

  def ident_menu
    "<span style='color:#3333FF;
        background-color:#{warped ? '#FBDF4F' : ''};
        font-size:120%;
        font-weight:bold;'>#{app_title}</span>"
  end

  def data_menus
    []
  end

  def menu
    return super unless self.class.has_any_perm?

    [ident_menu, sep] +
      (self.class.has_admin_perm? ||
       self.class.has_user_manager_perm? ? [system_menu, sep] : []) +
      data_menus +
      [
       applications_menu, sep,
       posting_menu, sep,
      ] + super
  end

  ######################################################################

  action :import_type_view do |a|
    a.text      = I18n.t("import_type")
    a.handler   = :netzke_load_component_by_action
    a.disabled  = !self.class.has_admin_perm?
    a.icon      = :table_go
  end

  action :scripting do |a|
    a.text      = I18n.t("scripting")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script
    a.disabled  = !self.class.has_any_perm?
  end

  action :reporting do |a|
    a.text      = I18n.t("reports")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :page_lightning
    a.disabled  = !self.class.has_any_perm?
  end

  action :promise_view do |a|
    a.text      = I18n.t("jobs.promise_view")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :report_magnify
    a.disabled  = !self.class.has_any_perm?
  end

  action :user_view do |a|
    a.text      = I18n.t("user_view")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :group
    a.disabled  = !self.class.has_admin_perm? &&
      !self.class.has_user_manager_perm?
  end

  action :event_view do |a|
    a.text      = I18n.t("event_view")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :application_view_list
    a.disabled  = !self.class.has_admin_perm?
  end

  action :config_view do |a|
    a.text      = I18n.t("config_view")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :cog
    a.disabled  = !self.class.has_admin_perm? &&
      !self.class.has_user_manager_perm?
  end

  action :api_auth_view do |a|
    a.text      = 'API Auth Management'
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script_key
    a.disabled  = !self.class.has_admin_perm?
  end

  action :api_config_view do |a|
    a.text      = 'API Config Management'
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script_key
    a.disabled  = !self.class.has_admin_perm?
  end

  action :api_log_view do |a|
    a.text      = 'API Log View'
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script_key
    a.disabled  = !self.class.has_admin_perm?
  end

  action :data_grid_view do |a|
    a.text      = I18n.t("data_grid_view", default: "Data Grids")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :table_multiple
    a.disabled  = !self.class.has_any_perm?
  end

  action :reload_scripts do |a|
    a.text     = 'Reload Scripts'
    a.tooltip  = 'Reload and tag Delorean scripts'
    a.icon     = :arrow_refresh
    a.disabled = !self.class.has_admin_perm?
  end

  action :load_seed do |a|
    a.text     = 'Load Seeds'
    a.tooltip  = 'Load Seeds'
    a.icon     = :arrow_rotate_clockwise
    a.disabled = !self.class.has_admin_perm?
  end

  action :bg_status do |a|
    a.text     = 'Show Delayed Jobs Status'
    a.tooltip  = 'Run delayed_job status script'
    a.icon     = :monitor
    a.disabled = !self.class.has_admin_perm?
  end

  action :bg_stop do |a|
    a.text     = 'Stop Delayed Jobs'
    a.tooltip  = 'Run delayed_job stop script'
    a.icon     = :stop
    a.disabled = !self.class.has_admin_perm?
  end

  action :bg_restart do |a|
    a.text     = 'Restart Delayed Jobs'
    a.tooltip  = 'Run delayed_job restart script using DELAYED_JOB_PARAMS'
    a.icon     = :arrow_rotate_clockwise
    a.disabled = !self.class.has_admin_perm?
  end

  action :log_view do |a|
    a.text     = 'View Log'
    a.tooltip  = 'View Log'
    a.handler  = :netzke_load_component_by_action
    a.icon      = :cog
    a.disabled = !self.class.has_admin_perm?
  end

  action :log_cleanup do |a|
    a.text     = 'Cleanup Log Table'
    a.tooltip  = 'Delete old log records'
    a.icon      = :cog
    a.disabled = !self.class.has_admin_perm?
  end

   ######################################################################

  def bg_command(param)
    e, root, p = ENV['RAILS_ENV'], Rails.root, Marty::Config["RUBY_PATH"]
    dj_path = Marty::Config["DELAYED_JOB_PATH"] || 'bin/delayed_job'
    cmd = "export RAILS_ENV=#{e};"
    # FIXME: Environment looks to be setup incorrectly - this is a hack
    cmd += "export PATH=#{p}:$PATH;" if p
    # 2>&1 redirects STDERR to STDOUT since backticks only captures STDOUT
    cmd += "#{root}/#{dj_path} #{param} 2>&1"
    cmd
  end

  endpoint :bg_status do |params|
    cmd = bg_command('status')
    res = `#{cmd}`
    client.show_detail res.html_safe.gsub("\n","<br/>"), 'Delayed Job Status'
  end

  endpoint :bg_stop do |params|
    cmd = bg_command("stop")
    res = `#{cmd}`
    res = "delayed_job: no instances running. Nothing to stop." if res.length==0
    client.show_detail res.html_safe.gsub("\n","<br/>"), 'Delayed Job Stop'
  end

  endpoint :bg_restart do |params|
    params = Marty::Config["DELAYED_JOB_PARAMS"] || ""
    cmd = bg_command("restart #{params}")
    res = `#{cmd}`
    client.show_detail res.html_safe.gsub("\n","<br/>"), 'Delayed Job Restart'
  end

  endpoint :log_cleanup do |params|
    begin
      Marty::Log.cleanup(params)
    rescue => e
      res = e.message
      client.show_detail res.html_safe.gsub("\n","<br/>"), 'Log Cleanup'
    end
  end

  ######################################################################
  # Postings

  action :new_posting do |a|
    a.text      = I18n.t('new_posting')
    a.tooltip   = I18n.t('new_posting')
    a.icon      = :time_add
    a.disabled  = Marty::Util.warped? || !self.class.has_posting_perm?
  end

  client_class do |c|
    c.show_detail = l(<<-JS)
    function(details, title) {
       this.hideLoadmask();
       Ext.create('Ext.Window', {
          height:        400,
          minWidth:      400,
          maxWidth:      1200,
          autoWidth:     true,
          modal:         true,
          autoScroll:    true,
          html:          details,
          title:         title || "Details"
      }).show();
    }
    JS

    c.show_loadmask = l(<<-JS)
    function(msg) {
      this.maskCmp = new Ext.LoadMask( {
        msg: msg || 'Loading...',
        target: this,
      });
      this.maskCmp.show();
    }
    JS

    c.hide_loadmask = l(<<-JS)
    function() {
      if (this.maskCmp) { this.maskCmp.hide(); };
    }
    JS

    c.netzke_on_new_posting = l(<<-JS)
    function(params) {
      this.netzkeLoadComponent("new_posting_window",
            { callback: function(w) { w.show(); },
      });
    }
    JS

    c.netzke_on_select_posting = l(<<-JS)
    function(params) {
      this.netzkeLoadComponent("posting_window",
            { callback: function(w) { w.show(); },
      });
    }
    JS

    c.netzke_on_reload = l(<<-JS)
    function(params) {
      window.location.reload();
    }
    JS

    c.netzke_on_load_seed = l(<<-JS)
    function(params) {
      this.server.loadSeed({});
    }
    JS

    c.netzke_on_select_now = l(<<-JS)
    function(params) {
      this.server.selectPosting({});
    }
    JS

    c.netzke_on_reload_scripts = l(<<-JS)
    function(params) {
       var me = this;
       Ext.Msg.show({
         title: 'Reload Scripts',
         msg: 'Enter RELOAD and press OK to force a reload of all scripts',
         width: 375,
         buttons: Ext.Msg.OKCANCEL,
         prompt: true,
         fn: function (btn, value) {
           btn == "ok" && value == "RELOAD" && me.server.reloadScripts({});
         }
       });
    }
    JS

    c.netzke_on_bg_stop = l(<<-JS)
    function(params) {
       var me = this;
       me.showLoadmask('Stopping delayed job...');
       Ext.Msg.show({
         title: 'Stop Delayed Jobs',
         msg: 'Enter STOP and press OK to force a stop of delayed_job',
         width: 375,
         buttons: Ext.Msg.OKCANCEL,
         prompt: true,
         fn: function (btn, value) {
           btn == "ok" && value == "STOP" && me.server.bgStop({});
         }
       });
    }
    JS

    c.netzke_on_bg_restart = l(<<-JS)
    function(params) {
       var me = this;
       me.showLoadmask('Restarting delayed job...');
       Ext.Msg.show({
         title: 'Restart Delayed Jobs',
         msg: 'Enter RESTART and press OK to force a restart of delayed_job',
         width: 375,
         buttons: Ext.Msg.OKCANCEL,
         prompt: true,
         fn: function (btn, value) {
           btn == "ok" && value == "RESTART" && me.server.bgRestart({});
         }
       });
    }
    JS

    c.netzke_on_bg_status = l(<<-JS)
    function() {
      this.showLoadmask('Checking delayed job status...');
      this.server.bgStatus({});
    }
    JS

    c.netzke_on_log_cleanup = l(<<-JS)
    function(params) {
       var me = this;
       Ext.Msg.show({
         title: 'Log Cleanup',
         msg: 'Enter number of days to keep',
         width: 375,
         buttons: Ext.Msg.OKCANCEL,
         prompt: true,
         fn: function (btn, value) {
           btn == "ok" && me.server.logCleanup(value);
         }
       });
    }
    JS

  end

  action :select_posting do |a|
    a.text      = I18n.t('select_posting')
    a.tooltip   = I18n.t('select_posting')
    a.icon      = :timeline_marker
  end

  endpoint :select_posting do |params|
    sid = params && params[0]
    Marty::Util.set_posting_id(sid)
    posting = sid && Marty::Posting.find(sid)

    client.netzke_notify "Selected '#{posting ? posting.name : 'NOW'}'"
    client.netzke_on_reload 1
  end

  action :select_now do |a|
    a.text      = I18n.t('go_to_now')
    a.icon      = :arrow_in
    a.disabled  = Marty::Util.get_posting_time == Float::INFINITY
  end

  ######################################################################

  component :scripting do |c|
    c.allow_edit = self.class.has_scripting_perm?
  end
  component :reporting
  component :promise_view
  component :posting_window
  component :new_posting_window do |c|
    c.disabled = Marty::Util.warped? || !self.class.has_posting_perm?
  end
  component :import_type_view
  component :user_view
  component :event_view
  component :config_view
  component :data_grid_view
  component :api_auth_view do |c|
    c.disabled = Marty::Util.warped?
  end
  component :api_log_view
  component :api_config_view

  component :log_view do |c|
    c.klass = Marty::LogView
  end

  endpoint :reload_scripts do |params|
    Marty::Script.load_scripts
    client.netzke_notify 'Scripts have been reloaded'
  end

  endpoint :load_seed do |params|
    Rails.application.load_seed
    client.netzke_notify 'Seeds have been loaded'
  end
end

MainAuthApp = Marty::MainAuthApp
