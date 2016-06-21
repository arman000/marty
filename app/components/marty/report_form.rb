class Marty::ReportForm < Marty::Form

  attr_accessor :background_only, :file_field, :text_area_field

  # override apply for background generation
  action :apply do |a|
    a.text     = a.tooltip = I18n.t("reporting.background")
    a.handler  = :netzke_on_apply
    a.icon     = :report_disk
    a.disabled = false
  end

  action :foreground do |a|
    a.text     = a.tooltip = I18n.t("reporting.generate")
    a.handler  = :netzke_on_apply
    a.icon     = :report_go
    a.disabled = false
  end

  ######################################################################

  def default_bbar
    [
      '->', :apply, :foreground
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

  endpoint :submit do |params|
    engine, d_params, node = self.class.get_report_engine(params)

    return client.netzke_notify "Insufficient permissions to run report!" unless
      engine

    file = params[file_field[:name]] if file_field
    if file
      if d_params[text_area_field[:name]]
        return client.netzke_notify "Must have file upload OR pasted text"
      end

      file_data = file.read
      d_params[text_area_field[:name]] = file_data
    end

    # start background promise to get report result
    begin
      res = engine.background_eval(node,
                                   d_params,
                                   ["result", "title", "format"],
                                  )

      if background_only
        return client.netzke_notify "Report can be accessed from the Jobs Dashboard ..."
      else
        job_id = force_promise_return(res)
        client.download_report job_id
      end
    rescue => exc
      Marty::Util.logger.error "run_eval failed: #{exc.backtrace}"
    end
  end

  def force_promise_return(res)
    promise_id = res.__promise__.id
    res.force
    promise_id
  end

  ######################################################################

  client_class do |c|
    c.download_report = l(<<-JS)
      function(jid) {
        // FIXME: seems pretty hacky
        window.location = "#{Marty::Util.marty_path}/job/download?job_id=" + jid;
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
    @background_only =
      engine.evaluate(root_sess[:selected_node], "background_only") rescue nil

    items = Marty::Xl.symbolize_keys(eval_form_items(engine, items), ':')
    items = [{html: "<br><b>No input is needed for this report.</b>"}] if
      items.empty?

    @file_field = items.find { |item| item[:xtype] == :filefield }
    @text_area_field = items.find { |item| item[:xtype] == :textareafield }

    # add hidden field for file upload
    if @file_field && !@text_area_field
      @text_area_field = {
        name:   'file_upload_text_field',
        xtype:  :textareafield,
        hidden: true,
      }
      items += [@text_area_field]
    end

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

    c.items              = items
    c.repformat          = format
    c.title              = "Generate: #{title}-#{sset.tag.name}"
    c.reptitle           = title
    c.authenticity_token = controller.send(:form_authenticity_token)

    actions[:foreground].excluded = !!background_only
    actions[:apply].excluded = !background_only
  end
end

ReportForm = Marty::ReportForm
