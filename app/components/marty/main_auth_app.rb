require 'marty/permissions'
require 'marty/scripting'
require 'marty/reporting'
require 'marty/posting_window'
require 'marty/new_posting_window'
require 'marty/import_type_view'
require 'marty/user_view'
require 'marty/promise_view'
require 'marty/api_auth_view'

class Marty::MainAuthApp < Marty::AuthApp
  extend ::Marty::Permissions

  # set of posting types user is allowed to post with
  def self.has_posting_perm?
    Marty::NewPostingForm.has_any_perm?
  end

  def self.has_data_import_perm?
    self.has_admin_perm?
  end

  def self.has_scripting_perm?
    self.has_admin_perm?
  end

  def sep
    { xtype: 'tbseparator' }
  end

  def icon_hack(name)
    # There's a Netzke bug whereby, using icon names in hashes
    # doesn't generate the proper URL.
    "#{Netzke::Core.ext_uri}/../images/icons/#{name}.png"
  end

  def posting_menu
    warped = Marty::Util.get_posting_time != Float::INFINITY
    wtext  = warped ? " [#{Marty::Util.get_posting.name}" : ''

    {
      text:  I18n.t("postings") + wtext,
      name:  "posting",
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
              :api_auth_view,
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

  def ident_menu
    '<span style="color:#B32D15; font-size:150%; font-weight:bold;">' +
      'Marty</span>'
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

  action :api_auth_view do |a|
    a.text      = I18n.t("api_auth_view", default: "API Authorization")
    a.handler   = :netzke_load_component_by_action
    a.icon      = :script_key
    a.disabled  = !self.class.has_admin_perm?
  end

  ######################################################################
  # Postings

  action :new_posting do |a|
    a.text      = I18n.t('new_posting')
    a.tooltip   = I18n.t('new_posting')
    a.icon      = :time_add
    a.disabled  = Marty::Util.warped? || !self.class.has_posting_perm?
  end

  js_configure do |c|
    c.on_new_posting = <<-JS
    function(params) {
      this.netzkeLoadComponent({
            name: "new_posting_window",
            callback: function(w) { w.show(); },
      });
    }
    JS

    c.on_select_posting = <<-JS
    function(params) {
      this.netzkeLoadComponent({
            name: "posting_window",
            callback: function(w) { w.show(); },
      });
    }
    JS

    c.on_reload = <<-JS
    function(params) {
      window.location.reload();
    }
    JS

    c.on_select_now = <<-JS
    function(params) {
      this.serverSelectPosting({});
    }
    JS
  end

  action :select_posting do |a|
    a.text      = I18n.t('select_posting')
    a.tooltip   = I18n.t('select_posting')
    a.icon      = :timeline_marker
  end

  endpoint :server_select_posting do |params, this|
    sid = params && params[0]
    Marty::Util.set_posting_id(sid)
    posting = sid && Marty::Posting.find(sid)

    this.netzke_feedback "Selected '#{posting ? posting.name : 'NOW'}'"
    this.on_reload 1
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
  component :api_auth_view do |c|
    c.disabled = Marty::Util.warped?
  end
end

MainAuthApp = Marty::MainAuthApp
