require 'delorean_lang'
require 'coderay'

class Marty::ScriptDetail < Marty::CmFormPanel
  DASH = 0x2012.chr('utf-8')

  css_configure do |c|
    c.require :codemirror
    c.require :delorean
  end

  js_configure do |c|
    c.require :"Ext.ux.form.field.CodeMirror"
    c.require :codemirror
    c.require "#{File.dirname(__FILE__)}/script_detail/javascripts/mode/delorean/delorean.js"

    c.set_action_modes = <<-JS
    	function(a) {
	   this.actions.apply.setDisabled(!a["save"]);
	   this.actions.checkin.setDisabled(!a["checkin"]);
	   this.actions.checkout.setDisabled(!a["checkout"]);
	   this.actions.discard.setDisabled(!a["discard"]);
	   // style input field text based on whether it is editable
	   this.getForm().findField('body').editor.setOption("readOnly", !a["save"]);
    	}
    	JS

    c.get_script_id = <<-JS
    	function() {
	   return this.getForm().findField('id').getValue();
    	}
    	JS

    c.get_script_body = <<-JS
    	function() {
	   return this.getForm().findField('body').getValue();
    	}
    	JS

    # Sets an editor line class (unset any previous line class).  For
    # now, only one line is classed at a time.
    c.set_line_error = <<-JS
    	function(line) {
	   line -= 1;
	   var editor = this.getForm().findField('body').editor;
	   if (editor.oldline) { editor.oldline.className = null; }
	   if (line > -1) {
	   	editor.oldline = editor.setLineClass(line, "errorline");
	   }
	   editor.refresh();
    	}
    	JS

    ######################################################################

    c.refresh_parent = <<-JS
    	function(script_id) {
	   this.netzkeGetParentComponent().scriptRefresh(script_id);
    	}
    	JS

    ######################################################################

    c.on_checkin = <<-JS
    	function() {
           var form_obj = this;
           Ext.Msg.show({
             title: 'Confirm Checkin',
             msg: 'Enter a checkin message:',
             width: 400,
             buttons: Ext.MessageBox.OKCANCEL,
             multiline: true,
             fn: function (btn, value, cfg) {
               (btn == "ok") && form_obj.serverCheckin(
             	{
     		body: form_obj.getScriptBody(),
     		logmsg: value,
     		script_id: form_obj.getScriptId(),
     		});
             },
           });
    	}
    	JS

    c.on_discard = <<-JS
    	function() {
           var form_obj = this;
           Ext.Msg.confirm('Confirm',
     	   'This action will remove the current DEV version.<br>' +
     	   'All changes since the last checkin <b>will be lost</b>. <br>' +
     	   'This action cannot be undone. Are your sure?',
                function (btn, value, cfg) {
                  (btn == "yes") && form_obj.serverDiscard({script_id: form_obj.getScriptId()});
                });
    	}
        JS

    c.on_checkout = <<-JS
    	function() {
	   this.serverCheckout({script_id: this.getScriptId()});
    	}
    	JS

    c.on_print = <<-JS
    	function() {
	  window.open("/marty/components/#{self.name}.html?script_id=" + this.getScriptId(),
		      "printing", 'width=800,height=700,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,copyhistory=no,resizable=yes');
    	}
    	JS
  end

  ######################################################################

  def get_title
    return unless @record

    status = @record.isdev? ? "Checked out by #{@record.group_dscript.user}" :
      "Checked in by #{@record.user}"

    [@record.name, "Ver: #{@record.version}", status].
      join(" #{Marty::ScriptDetail::DASH} ")
  end

  def isdev?
    @record && @record.isdev?
  end

  def istip?
    @record && @record.istip?
  end

  def ismodified?
    @record && @record.differs_from_dscript?
  end

  ######################################################################

  def can_save?(ds)
    config[:allow_edit] || (ds.user == Mcfly.whodunnit)
  end

  def can_checkin?(ds)
    ds.user == Mcfly.whodunnit
  end

  def can_discard?(ds)
    config[:allow_edit] || (ds.user == Mcfly.whodunnit)
  end

  def can_checkout?
    config[:allow_edit]
  end

  ######################################################################

  endpoint :netzke_load do |params, this|
    unless self.class.has_any_perm?
      this.netzke_feedback "Permission Denied"
      return
    end

    # logic copied from basepack's form_panel.service
    @record = Marty::Script.find_by_id(params[:id])

    this.set_form_values js_record_data
    this.set_title get_title
    this.set_readonly_mode !isdev?

    modes = {
      save: 	isdev? && can_save?(@record.group_dscript),
      checkin: 	isdev? && ismodified? && can_checkin?(@record.group_dscript),
      checkout: istip? && !@record.dscript && can_checkout?,
      discard: 	isdev? && can_discard?(@record.group_dscript),
    }

    this.set_action_modes(modes)
  end

  ######################################################################

  action :apply do |a|
    a.text  	= I18n.t("script_detail.save")
    a.tooltip  	= I18n.t("script_detail.save")
    a.icon  	= :database_save
    a.disabled 	= true
  end

  endpoint :netzke_submit do |params, this|
    unless self.class.has_any_perm?
      this.netzke_feedback "Permission Denied"
      return
    end

    # p 'X'*30, params

    # copied from corresponding method in form_panel.services
    data = ActiveSupport::JSON.decode(params[:data])
    data.each_pair do |k,v|
      data[k] = nil if v.blank? || v == "null"
    end

    @record = Marty::Script.find_by_id(data["id"])

    # p 'd.'*30, data, @record

    unless @record
      this.netzke_feedback "no record"
      return
    end

    ds = @record.group_dscript

    unless ds
      this.netzke_feedback "no dev record"
      return
    end

    if ds.body == data["body"]
      this.netzke_feedback "no save needed"
      # clear the error line if any
      this.set_line_error -1
      return
    end

    unless can_save?(ds)
      this.netzke_feedback "Permission denied"
      return
    end

    begin
      engine = Marty::ScriptSet.parse(@record.name, data["body"])
    rescue Delorean::ParseError => exc
      this.netzke_feedback exc.message
      this.apply_form_errors({})
      this.set_line_error(exc.line)
      return
    end

    ds.body = data["body"]

    if ds.save
      this.set_form_values(js_record_data)
      this.netzke_set_result(true)
      this.refresh_parent(@record.id)
      return
    end

    data_adapter.errors_array(ds).each do |error|
      flash error: error
    end

    this.netzke_feedback @flash
    this.apply_form_errors(build_form_errors(record))
  end

  ######################################################################

  action :checkin do |a|
    a.text  	= I18n.t("script_detail.checkin")
    a.tooltip  	= I18n.t("script_detail.checkin")
    a.icon  	= :tag_blue_add
    a.disabled 	= true
  end

  endpoint :server_checkin do |params, this|
    @record = Marty::Script.find_by_id(params[:script_id])

    unless @record
      this.netzke_feedback "no record"
      return
    end

    ds = @record.group_dscript

    unless ds
      this.netzke_feedback "no dev record"
      return
    end

    if ds.body != params[:body]
      this.netzke_feedback "Error: Unsaved changes. Save before checkin."
      return
    end

    unless can_checkin?(ds)
      this.netzke_feedback "Permission denied"
      return
    end

    ds.checkin(params[:logmsg])

    this.netzke_feedback "checkin done"
    this.refresh_parent @record.group_id
  end

  ######################################################################

  action :checkout do |a|
    a.text  	= I18n.t("script_detail.checkout")
    a.tooltip  	= I18n.t("script_detail.checkout")
    a.icon  	= :tag_blue_edit
    a.disabled 	= true
  end

  endpoint :server_checkout do |params, this|
    @record = Marty::Script.find_by_id(params[:script_id])

    unless @record
      this.netzke_feedback "no record"
      return
    end

    unless can_checkout?
      this.netzke_feedback "Permission denied"
      return
    end

    begin
      @record.checkout
    rescue => exc
      this.netzke_feedback exc.message
      return
    end

    this.netzke_feedback I18n.t("script_detail.checked_out")
    this.refresh_parent @record.dev_version.id
  end

  ######################################################################

  action :discard do |a|
    a.text  	= I18n.t("script_detail.discard")
    a.tooltip  	= I18n.t("script_detail.discard")
    a.icon  	= :tag_blue_delete
    a.disabled 	= true
  end

  endpoint :server_discard do |params, this|
    r = Marty::Script.find_by_id(params[:script_id])

    unless r
      this.netzke_feedback "no record"
      return
    end

    @record = r.last_version

    unless @record.dscript
      this.netzke_feedback "no dev record"
      return
    end

    unless can_discard?(@record.dscript)
      this.netzke_feedback "Permission denied"
      return
    end

    @record.dscript.discard

    this.netzke_feedback I18n.t("script_detail.discarded")
    this.refresh_parent(@record.isdev? ? -1 : @record.group_id)
  end

  ######################################################################

  action :print do |a|
    a.text  	= I18n.t("script_detail.print")
    a.tooltip  	= I18n.t("script_detail.print")
    a.icon  	= :printer
    a.handler	= :on_print
  end

  ######################################################################

  def configure_bbar(c)
    c[:bbar] = [
                :apply,
                :checkin,
                :checkout,
                :discard,
                :print,
               ]
  end

  ######################################################################

  # used for printing
  def generate_html(params={})
    r = Marty::Script.find_by_id(params[:script_id])
    body = get_body(r)
    CodeRay.scan(body, :ruby).div(:line_numbers => :table)
  end

  def get_body(r)
    r = r.group_dscript if r.isdev?
    r ? r.body : "ERROR: NO BODY"
  end

  def configure(c)
    super

    c.allow_edit = true if c.allow_edit.nil? && ENV["RAILS_ENV"] == "test"

    c.title = "Script Detail"
    c.model = "Marty::Script"
    c.items = [
               {
                 mode: 			"text/x-delorean",
                 line_numbers: 		true,
                 indent_unit: 		4,
                 tab_mode: 		"shift",
                 match_brackets: 	true,

                 hide_label:		true,
                 xtype: 		:codemirror,
                 name: 			:body,
                 empty_text: 		"No script selected.",
                 getter: 		lambda { |r| get_body(r) },
               },
              ]
  end
end

ScriptDetail = Marty::ScriptDetail
