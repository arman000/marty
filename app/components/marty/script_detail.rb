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
    c.require File.dirname(__FILE__) +
      "/script_detail/javascripts/mode/delorean/delorean.js"

    c.set_action_modes = <<-JS
    function(a) {
       this.actions.apply.setDisabled(!a["save"]);
       // style input field text based on whether it is editable
       this.getForm().findField('body').editor.setOption(
          "readOnly", !a["save"]);
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
       if (editor.oldline) {
          editor.oldline.className = null;
       }
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

    c.on_print = <<-JS
    function() {
       window.open(
          "/marty/components/#{self.name}.html?script_id=" + this.getScriptId(),
          "printing",
          'width=800,height=700,toolbar=no,location=no,directories=no,'+
          'status=no,menubar=no,scrollbars=yes,copyhistory=no,resizable=yes');
    }
    JS
  end

  ######################################################################

  endpoint :netzke_load do |params, this|

    return this.netzke_feedback("Permission Denied") unless
      self.class.has_any_perm?

    # logic from basepack's form_panel.service -- need to set @record.
    @record = script = Marty::Script.find_by_id(params[:id])

    title = [script.name, script.find_tag.try(:name)].
      join(" #{Marty::ScriptDetail::DASH} ") if script

    this.set_form_values js_record_data
    this.set_title title
    this.set_readonly_mode !can_save?(script)

    modes = {
      save: can_save?(script),
    }

    this.set_action_modes(modes)
  end

  def can_save?(script)
    # FIXME: check for save permissions

    script && Mcfly.is_infinity(script.obsoleted_dt)
  end

  ######################################################################

  action :apply do |a|
    a.text     = I18n.t("script_detail.save")
    a.tooltip  = I18n.t("script_detail.save")
    a.icon     = :database_save
    a.disabled = true
  end

  endpoint :netzke_submit do |params, this|

    return this.netzke_feedback("Permission Denied") unless
      self.class.has_any_perm?

    # copied from corresponding method in form_panel.services
    data = ActiveSupport::JSON.decode(params[:data])
    data.each_pair do |k,v|
      data[k] = nil if v.blank? || v == "null"
    end

    @record = script = Marty::Script.find_by_id(data["id"])

    unless script
      this.netzke_feedback "no record"
      return
    end

    if script.body == data["body"]
      this.netzke_feedback "no save needed"
      # clear the error line if any
      this.set_line_error -1
      return
    end

    unless can_save?(script)
      this.netzke_feedback "Permission denied"
      return
    end

    begin
      dev = Marty::Tag.find_by_name("DEV")
      Marty::ScriptSet.new(dev).parse_check(script.name, data["body"])
    rescue Delorean::ParseError => exc
      this.netzke_feedback exc.message
      this.apply_form_errors({})
      this.set_line_error(exc.line)
      return
    end

    script.body = data["body"]

    if script.save
      this.set_form_values(js_record_data)
      this.netzke_set_result(true)
      this.refresh_parent(script.id)
      return
    end

    data_adapter.errors_array(script).each do |error|
      flash error: error
    end

    this.netzke_feedback @flash
    this.apply_form_errors(build_form_errors(record))
  end

  ######################################################################

  action :print do |a|
    a.text    = I18n.t("script_detail.print")
    a.tooltip = I18n.t("script_detail.print")
    a.icon    = :printer
    a.handler = :on_print
  end

  ######################################################################

  def configure_bbar(c)
    c[:bbar] = [
                :apply,
                :print,
               ]
  end

  ######################################################################

  # used for printing
  def export_content(format, title, params={})
    raise "unknown format: #{format}" unless format == "html"

    r = Marty::Script.find_by_id(params[:script_id])
    res = CodeRay.scan(r.body, :ruby).div(line_numbers: :table)

    [res, "text/html", "inline", "#{title}.html"]
  end

  def configure(c)
    super

    # FIXME: do something with allow_edit???

    c.title = "Script Detail"
    c.model = "Marty::Script"
    c.items =
      [
       {
	 mode:			"text/x-delorean",
	 line_numbers:		true,
	 indent_unit:		4,
	 tab_mode:		"shift",
	 match_brackets:	true,
	 hide_label:		true,
	 xtype:			:codemirror,
	 name:			:body,
	 empty_text:		"No script selected.",
	 getter:		lambda { |r| r.body },
       },
      ]
  end
end

ScriptDetail = Marty::ScriptDetail
