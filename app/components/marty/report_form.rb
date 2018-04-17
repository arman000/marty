class Marty::ReportForm < Marty::Form

  # override apply for background generation
  action :apply do |a|
    a.text     = a.tooltip = I18n.t("reporting.background")
    a.handler  = :netzke_on_apply
    a.icon     = :report_disk
    a.disabled = false
  end

  action :foreground do |a|
    a.text     = a.tooltip = I18n.t("reporting.generate")
    a.icon     = :report_go
    a.disabled = false
  end

  action :link do |a|
    a.text     = a.tooltip = I18n.t("reporting.link")
    a.icon     = :link_go
    a.disabled = false
  end

  ######################################################################

  def default_bbar
    [
      '->', :apply, :foreground, :link
    ]
  end

  ######################################################################

  def self.get_report_engine(params)
    d_params = ActiveSupport::JSON.decode(params[:data] || "{}")
    d_params.each_pair do |k,v|
      d_params[k] = nil if v.blank? || v == "null"
    end

    tag_id      = d_params.delete("selected_tag_id")
    script_name = d_params.delete("selected_script_name")
    node        = d_params.delete("selected_node")

    engine = Marty::ScriptSet.new(tag_id).get_engine(script_name)

    roles = engine.evaluate(node, "roles", {}) rescue nil

    if roles && !roles.any?{ |r| Marty::User.has_role(r) }
      # insufficient permissions
      return []
    end

    d_params["p_title"] ||= engine.evaluate(node, "title", {}).to_s

    [engine, d_params, node]
  end

  def self.run_eval(params)
    engine, d_params, node = get_report_engine(params)

    raise "Insufficient permissions" unless engine
    raise "no selected report node" unless String === node

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

  endpoint :submit do |params|
    # We get here when user is asking for a background report

    engine, d_params, node = self.class.get_report_engine(params)

    return client.netzke_notify "Insufficient permissions to run report!" unless
      engine

    # start background promise to get report result
    engine.background_eval(node,
                           d_params,
                           ["result", "title", "format"],
                           )

    client.netzke_notify "Report can be accessed from the Jobs Dashboard ..."
  end

  ######################################################################

  client_class do |c|
    # Find the mount path for the Marty engine. FIXME: this is likely
    # very brittle.
    @@mount_path = Rails.application.routes.routes.detect {
      |r| r.app.app == Marty::Engine
    }.format({})

    c.netzke_on_foreground = l(<<-JS)
    function() {
       var values = this.getForm().getValues();
       var data = Ext.encode(values);

       var params = {data: data, reptitle: this.reptitle};

       // very hacky -- when selected_testing is set, we assume we're
       // testing and try to inline the result.
       if (values["selected_testing"]) {
          this.repformat = "txt";
          params["disposition"] = "inline";
       }

       var form = document.createElement("form");

       form.setAttribute("method", "post");
       form.setAttribute("action", "#{@@mount_path}/report."+this.repformat);

       // set authenticity token
       var hiddenField = document.createElement("input");
       hiddenField.setAttribute("type", "hidden");
       hiddenField.setAttribute("name", "authenticity_token");
       hiddenField.setAttribute("value", this.authenticityToken);
       form.appendChild(hiddenField);

       for (var key in params) {
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

    c.netzke_on_link = l(<<-JS)
    function() {
       var values = this.getForm().getValues();

       // check for early url generation and exit with error message
       if (values['selected_script_name'] == null) {
         alert("Please select a report before generating url.");
         return;
       }

       params = {
         "format": this.repformat,
         "reptitle": this.reptitle
       }

       for (var key in values) {if (values[key] == "") {delete values[key]}}
       data = Ext.encode(values)

       // construct url
       var proto_host = location.protocol + '//' + location.host
       var url  = proto_host + '/report?data=' + data
       for (var key in params) {
         if (params[key] == "") continue;
         url += '&' + key + '=' + params[key];
       }
       url = encodeURI(url)
       var win = window.open('');
       win.document.write(url.link(url));
     }
    JS
  end

  endpoint :netzke_load do |params|
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
        evaluate(root_sess[:selected_node],
                       ["form", "title", "format"],
                       {},
                       )

      raise "bad form items" unless items.is_a?(Array)
      raise "bad format" unless
        Marty::ContentHandler::GEN_FORMATS.member?(format)

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

    # add hidden fields for selected tag/script/node
    items += [:selected_tag_id,
              :selected_script_name,
              :selected_node,
              # just for testing
              :selected_testing,
             ].map { |f|
      {
        name:   f,
        xtype:  :textfield,
        hidden: true,
        value:  root_sess[f],
      }
    }

    c.items              = add_cls_to_fields(items)
    c.repformat          = format
    c.title              = "Generate: #{title}-#{sset.tag.name}"
    c.reptitle           = title
    c.authenticity_token = controller.send(:form_authenticity_token)

    [:foreground, :link].each{|a| actions[a].disabled = !!background_only}
  end
end

ReportForm = Marty::ReportForm
