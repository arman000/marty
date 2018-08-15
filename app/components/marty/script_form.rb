class Marty::ScriptForm < Marty::Form
  DASH = 0x2012.chr('utf-8')

  client_styles do |c|
    c.require :codemirror
    c.require :delorean
  end

  client_class do |c|
    c.require :"Ext.ux.form.field.CodeMirror"
    c.require :codemirror
    c.require File.dirname(__FILE__) +
      "/script_form/client/mode/delorean/delorean.js"

    c.set_action_modes = l(<<-JS)
    function(a) {
       this.actions.apply.setDisabled(!a["save"]);
       // style input field text based on whether it is editable
       this.getForm().findField('body').editor.setOption(
          "readOnly", !a["save"]);
    }
    JS

    c.get_script_id = l(<<-JS)
    function() {
       return this.getForm().findField('id').getValue();
    }
    JS

    # Sets an editor line class (unset any previous line class).  For
    # now, only one line is classed at a time.
    c.set_line_error = l(<<-JS)
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

    c.refresh_parent = l(<<-JS)
    function(script_name) {
       this.netzkeGetParentComponent().scriptRefresh(script_name);
    }
    JS

    ######################################################################

    c.netzke_on_do_print = l(<<-JS)
    function(params) {
      this.server.doPrint(this.getScriptId());
    }
    JS

    c.get_report = l(<<-JS)
    function(report_path) {
      window.location = report_path;
    }
    JS
  end

  ######################################################################

  endpoint :netzke_load do |params|

    return client.netzke_notify("Permission Denied") unless
      self.class.has_any_perm?

    script_name = params[:script_name]
    tag_id = root_sess[:selected_tag_id]

    # logic from basepack's form_panel.service -- need to set @record.
    @record = script = Marty::Script.find_script(script_name, tag_id)

    title = [script.name, script.find_tag.try(:name)].
      join(" #{Marty::ScriptForm::DASH} ") if script

    # create an empty record if no script
    js_data = @record ? js_record_data : {
      "body" => "",
      "id"   => -1,
      "meta" => {},
    }

    client.netzke_set_form_values(js_data)
    client.set_title title
    client.netzke_set_readonly_mode !can_save?(script)

    modes = {
      save: can_save?(script),
    }

    client.set_action_modes(modes)
  end

  def can_save?(script)
    script && self.class.has_dev_perm? && Mcfly.is_infinity(script.obsoleted_dt)
  end

  ######################################################################

  action :apply do |a|
    a.text     = I18n.t("script_form.save")
    a.tooltip  = I18n.t("script_form.save")
    a.icon_cls = "fa fa-save glyph"
    a.disabled = true
  end

  endpoint :submit do |params|

    return client.netzke_notify("Permission Denied") unless
      self.class.has_any_perm?

    # copied from corresponding method in form_panel.services
    data = ActiveSupport::JSON.decode(params[:data])
    data.each_pair do |k,v|
      data[k] = nil if v.blank? || v == "null"
    end

    @record = script = Marty::Script.find_by_id(data["id"])

    unless script
      client.netzke_notify "no record"
      return
    end

    if script.body == data["body"]
      client.netzke_notify "no save needed"
      # clear the error line if any
      client.set_line_error -1
      return
    end

    unless can_save?(script)
      client.netzke_notify "Permission denied"
      return
    end

    begin
      dev = Marty::Tag.find_by_name("DEV")
      Marty::ScriptSet.new(dev).parse_check(script.name, data["body"])
    rescue Delorean::ParseError => exc
      client.netzke_notify exc.message
      client.netzke_apply_form_errors({})
      client.set_line_error(exc.line)
      return
    end

    script.body = data["body"]

    if script.save
      client.netzke_set_form_values(js_record_data)
      client.refresh_parent(script.name)
      return true
    end

    client.netzke_notify(model_adapter.errors_array(script).join("\n"))
    client.netzke_apply_form_errors(build_form_errors(record))
  end

  endpoint :do_print do |script_id|
    return client.netzke_notify("Permission Denied") unless
      self.class.has_any_perm?

    script = Marty::Script.find_by_id(script_id)

    return client.netzke_notify("bad script") unless script

    begin
      rep_params = {
        script_id: script.id,
        title: script.name
      }

      path = Marty::Util.gen_report_path("ScriptReport",
                                         "PrettyScript",
                                         rep_params)
      client.get_report(path)
    rescue => exc
      return client.netzke_notify "ERROR: #{exc}"
    end
  end

  ######################################################################

  action :do_print do |a|
    a.text     = I18n.t("script_form.print")
    a.tooltip  = I18n.t("script_form.print")
    a.icon_cls = "fa fa-print glyph"
  end

  ######################################################################

  def default_bbar
    [
      :apply,
      :do_print,
    ]
  end

  ######################################################################

  def configure(c)
    super

    c.title = "Script Form"
    c.model = "Marty::Script"
    c.items =
      [
       {
         mode:           "text/x-delorean",
         line_numbers:   true,
         indent_unit:    4,
         tab_mode:       "shift",
         match_brackets: true,
         hide_label:     true,
         xtype:          :codemirror,
         name:           :body,
         empty_text:     "No script selected.",
         getter:         lambda { |r| r.body },
       },
      ]
  end
end

ScriptForm = Marty::ScriptForm
