require 'marty/permissions'
require 'marty/scripting'
require 'marty/reporting'
require 'marty/posting_window'
require 'marty/new_posting_window'
require 'marty/import_type_view'
require 'marty/import_synonym_view'
require 'marty/data_import_view'
require 'marty/user_view'

class Marty::MainAuthApp < Marty::AuthApp
  extend Marty::Permissions

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

    {
      text: I18n.t("postings") +
      (warped ? " [#{Marty::Util.get_posting.name}]" : ""),
      icon: icon_hack(:time),
      style: (warped ? "background-color: lightGrey;" : ""),
      menu: [
             :new_posting,
             :select_posting,
             :select_now,
            ],
    }
  end

  def system_menu
    {
      text: I18n.t("system"),
      icon: icon_hack(:wrench),
      style: "",
      menu: [
             :import_type_view,
             :import_synonym_view,
             :user_view,
            ],
    }
  end

  def applications_menu
    {
      text:	I18n.t("applications"),
      icon:	icon_hack(:application_cascade),
      menu:	[
                 :reporting,
                 :scripting,
                 :data_import_view,
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
      (self.class.has_admin_perm? ? [system_menu, sep] : []) +
      data_menus +
      [
       applications_menu, sep,
       posting_menu, sep,
      ] + super
  end

  ######################################################################

  action :import_type_view do |a|
    a.text 	= I18n.t("import_type")
    a.handler  	= :netzke_load_component_by_action
    a.disabled 	= !self.class.has_admin_perm?
  end

  action :import_synonym_view do |a|
    a.text 	= I18n.t("import_synonym")
    a.handler  	= :netzke_load_component_by_action
    a.disabled 	= !self.class.has_admin_perm?
  end

  action :mando_loan_program_view do |a|
    a.text 	= I18n.t("mando_loan_program")
    a.handler  	= :netzke_load_component_by_action
    a.disabled 	= !self.class.has_admin_perm?
  end

  action :scripting do |a|
    a.text    	= I18n.t("scripting")
    a.handler 	= :netzke_load_component_by_action
    a.icon    	= :script
  end

  action :reporting do |a|
    a.text 	= I18n.t("reports")
    a.handler 	= :netzke_load_component_by_action
    a.icon 	= :page_lightning
  end

  action :data_import_view do |a|
    a.text 	= I18n.t("data_import_view.import_data")
    a.handler 	= :netzke_load_component_by_action
    a.icon 	= :database_go
  end

  action :user_view do |a|
    a.text 	= I18n.t("user_view")
    a.handler 	= :netzke_load_component_by_action
    a.disabled 	= !self.class.has_admin_perm?
  end

  ######################################################################
  # Postings

  action :new_posting do |a|
    a.text 	= I18n.t('new_posting')
    a.tooltip 	= I18n.t('new_posting')
    a.icon 	= :time_add
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
    a.text 	= I18n.t('select_posting')
    a.tooltip 	= I18n.t('select_posting')
    a.icon 	= :timeline_marker
  end

  endpoint :server_select_posting do |params, this|
    sid = params && params[0]
    Marty::Util.set_posting_id(sid)
    posting = sid && Marty::Posting.find(sid)

    this.netzke_feedback "Selected '#{posting ? posting.name : 'NOW'}'"
    this.on_reload 1
  end

  action :select_now do |a|
    a.text 	= I18n.t('go_to_now')
    a.icon 	= :arrow_in
    a.disabled 	= Marty::Util.get_posting_time == Float::INFINITY
  end

  ######################################################################

  component :scripting
  component :reporting
  component :posting_window
  component :new_posting_window
  component :import_type_view
  component :import_synonym_view
  component :data_import_view
  component :user_view
end

MainAuthApp = Marty::MainAuthApp
