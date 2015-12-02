require 'delorean_lang'

class Marty::ReportForm < Marty::Form

  # override apply for background generation
  action :apply do |a|
    a.text     = a.tooltip = I18n.t("reporting.background")
    a.handler  = :on_apply
    a.icon     = :report_disk
    a.disabled = false
  end

  action :foreground do |a|
    a.text     = a.tooltip = I18n.t("reporting.generate")
    a.handler  = :on_foreground
    a.icon     = :report_go
    a.disabled = false
  end

  ######################################################################

  def configure_bbar(c)
    c[:bbar] = ['->', :apply, :foreground]
  end

  ######################################################################

  # FIXME: Most of the following functionality should be moved out to
  # a library.  It doesn't belong here in a component.  These are
  # currently also getting called form the report controller.

  # FIXME: The usage of session/root_sess should be entirely removed.
  # Instead we should send in :selected_node, :selected_tag_id,
  # :selected_script_name as params.

  def self.get_report_engine(params, session)
    d_params = ActiveSupport::JSON.decode(params[:data] || "{}")
    d_params.each_pair do |k,v|
      d_params[k] = nil if v.blank? || v == "null"
    end

    tag_id, script_name =
      session[:selected_tag_id], session[:selected_script_name]

    engine = Marty::ScriptSet.new(tag_id).get_engine(script_name)

    [engine, d_params]
  end

  def self.run_eval(params, session)
    node = session[:selected_node]

    raise "no selected report node" unless String === node

    engine, d_params = get_report_engine(params, session)

    begin
      engine.evaluate(node, "result", d_params)
    rescue => exc
      Marty::Util.logger.error "run_eval failed: #{exc.backtrace}"

      res = Delorean::Engine.grok_runtime_exception(exc)
      res["backtrace"] =
        res["backtrace"].map {|m, line, fn| "#{m}:#{line} #{fn}"}.join('\n')
      res
    end
  end

  def export_content(format, title, params={})
    data = self.class.run_eval(params, session)

    # hacky: shouldn't have error parsing logic here
    format = "json" if data.is_a?(Hash) && (data[:error] || data["error"])

    # hack for testing -- txt -> csv
    exp_format = format == "txt" ? "csv" : format

    res, type, disposition, filename =
      Marty::ContentHandler.export(data, exp_format, title)

    # hack for testing -- set content-type
    type = "text/plain" if format == "txt" && type =~ /csv/

    [res, type, disposition, filename]
  end

  endpoint :netzke_submit do |params, this|
    # We get here when user is asking for a background report

    engine, d_params = self.class.get_report_engine(params, session)

    roles = engine.
      evaluate(session[:selected_node], "roles", {}) rescue nil

    if roles && !roles.any?{ |r| Marty::User.has_role(r) }
      this.netzke_feedback "Insufficient permissions to run report!"
      return
    end

    d_params["p_title"] ||= engine.
      evaluate(session[:selected_node], "title", {}).to_s

    # start background promise to get report result
    engine.background_eval(session[:selected_node],
                           d_params,
                           ["result", "title", "format"],
                           )

    this.netzke_feedback "Report can be accessed from the Jobs Dashboard ..."
  end

  ######################################################################

  js_configure do |c|
    # Find the mount path for the Marty engine. FIXME: this is likely
    # very brittle.
    @@mount_path = Rails.application.routes.routes.detect {
      |r| r.app.app == Marty::Engine
    }.format({})

    c.on_foreground = <<-JS
    function() {
       var values = this.getForm().getValues();
       var data = Ext.encode(values);

       var form = document.createElement("form");
       form.setAttribute("method", "post");
       form.setAttribute("action", "#{@@mount_path}/report."+this.repformat);

       var params = {data: data, reptitle: this.reptitle};

       for(var key in params) {
          if (params.hasOwnProperty(key)) {
             var hiddenField = document.createElement("input");
             hiddenField.setAttribute("type", "hidden");
             hiddenField.setAttribute("name", key);
             hiddenField.setAttribute("value", params[key]);

            form.appendChild(hiddenField);
          }
       }

       document.body.appendChild(form);
       form.submit();
       document.body.removeChild(form);
    }
    JS
  end

  endpoint :netzke_load do |params, this|
  end

  def eval_form_items(engine, items)
    case items
    when Array
      items.map {|x| eval_form_items(engine, x)}
    when Hash
      items.each_with_object({}) { |(key, value), result|
        result[key] = eval_form_items(engine, value)
      }
    when String
      items.starts_with?(':') ? items[1..-1].to_sym : items
    when Class
      raise "bad value in form #{items}" unless
        items < Delorean::BaseModule::BaseClass

      attrs = engine.enumerate_attrs_by_node(items)

      engine.eval_to_hash(items, attrs, {})
    when Numeric, TrueClass, FalseClass
      items
    else
      raise "bad value in form #{items}"
    end
  end

  def configure(c)
    super

    unless root_sess[:selected_script_name] && root_sess[:selected_node]
      c.title = "No Report selected."
      return
    end

    begin
      sset = Marty::ScriptSet.new(root_sess[:selected_tag_id])
      engine = sset.get_engine(root_sess[:selected_script_name])

      raise engine.to_s if engine.is_a?(Hash)

      items, title, format = engine.
        evaluate_attrs(root_sess[:selected_node],
                       ["form", "title", "format"],
                       {},
                       )

      raise "bad form items" unless items.is_a?(Array)
      raise "bad format" unless
        ["csv", "xlsx", "zip", "json"].member?(format)
    rescue => exc
      c.title = "ERROR"
      c.items =
        [
         {
           field_label: 'Exception',
           xtype:       :displayfield,
           name:        'displayfield1',
           value:       "<span style=\"color:red;\">#{exc}</span>"
         },
        ]
      return
    end

    # if there's a background_only flag, we disable the foreground submit
    background_only =
      engine.evaluate(root_sess[:selected_node], "background_only") rescue nil

    items = Marty::Xl.symbolize_keys(eval_form_items(engine, items), ':')

    items = [{html: "<br><b>No input is needed for this report.</b>"}] if
      items.empty?

    # Hacky: store these globally in session so we can get them on
    # report generation request which comes out of band.  Also, if the
    # user's script/tag selection changes, we don't need to redraw
    # report_form.
    session[:selected_tag_id]      = root_sess[:selected_tag_id]
    session[:selected_script_name] = root_sess[:selected_script_name]
    session[:selected_node]        = root_sess[:selected_node]

    c.items     = items
    c.repformat = format
    c.title     = "Generate: #{title}-#{sset.tag.name}"
    c.reptitle  = title

    actions[:foreground].disabled = !!background_only
  end
end

ReportForm = Marty::ReportForm
