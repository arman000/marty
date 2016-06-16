require 'marty/scripting'
require 'marty/reporting'
require 'marty/posting_window'
require 'marty/new_posting_window'
require 'marty/import_type_view'
require 'marty/user_view'
require 'marty/promise_view'
require 'marty/api_auth_view'
require 'marty/config_view'

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
    "#{Netzke::Core.ext_uri}/../images/icons/#{name}.png"
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

  def system_menu
    {
      text:  I18n.t("system"),
      icon:  icon_hack(:wrench),
      style: "",
      menu:  [
              :import_type_view,
              :user_view,
              :config_view,
              :api_auth_view,
              :reload_scripts,
             ],
    }
  end

  def applications_menu
    {
      text: I18n.t("applications"),
      icon: icon_hack(:application_cascade),
      menu: [
             :reporting,
             :scripting,
             :promise_view,
            ],
    }
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

  action :config_view do |a|
    a.text      = I18n.t("config_view")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :cog
    a.disabled  = !self.class.has_admin_perm? &&
      !self.class.has_user_manager_perm?
  end

  action :api_auth_view do |a|
    a.text      = I18n.t("api_auth_view", default: "API Authorization")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script_key
    a.disabled  = !self.class.has_admin_perm?
  end

  action :reload_scripts do |a|
    a.text     = 'Reload Scripts'
    a.tooltip  = 'Reload and tag Delorean scripts'
    a.icon     = :arrow_refresh
    a.disabled = !self.class.has_admin_perm?
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
  component :config_view
  component :api_auth_view do |c|
    c.disabled = Marty::Util.warped?
  end

  endpoint :reload_scripts do |params|
    Marty::Script.load_scripts
    client.netzke_notify 'Scripts have been reloaded'
  end
end

MainAuthApp = Marty::MainAuthApp
