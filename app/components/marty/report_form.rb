require 'delorean_lang'

class Marty::ReportForm < Marty::CmFormPanel

  attr_accessor :filename

  action :apply do |a|
    a.text  	= I18n.t("reporting.generate")
    a.tooltip  	= I18n.t("reporting.generate")
    a.handler  	= :on_apply
    a.icon  	= :application_put
    a.disabled 	= false
  end

  ######################################################################

  def run_eval(params)
    data = ActiveSupport::JSON.decode(params[:data] || "{}")
    data.each_pair do |k,v|
      data[k] = nil if v.blank? || v == "null"
    end

    engine = Marty::ScriptSet.get_engine(session[:selected_script_id])

    begin
      return engine.evaluate(session[:selected_node], "result", data)

    rescue => exc
      Marty::Util.logger.error "run_eval failed: #{exc.backtrace}"

      err, bt = engine.parse_runtime_exception(exc)

      return {
        "error" => err.to_s,
        "backtrace" => bt.map {|m, line, fn| "#{m}:#{line} #{fn}"}.join('\n'),
      }
    end
  end

  def generate_csv(params={})
    res = run_eval(params)
    Marty::DataExporter.to_csv(res)
  end

  # Used for testing
  def generate_txt(params={})
    generate_csv(params)
  end

  def generate_xlsx(params={})
    res = run_eval(params)

    begin
      xlsx_report = Marty::Xl.spreadsheet(res)

      return xlsx_report.to_stream.read
    rescue => exc
      Marty::Util.logger.error "generate_xlsx failed: #{exc.backtrace}"
      return exc.to_s
    end
  end

  ######################################################################

  js_configure do |c|
    c.on_apply = <<-JS
      function() {
	var values = this.getForm().getValues();
	var data = escape(Ext.encode(values));
	// FIXME: hard-coded path
	window.location = "/marty/components/#{self.name}." + this.repformat + "?data=" + data;
      }
      JS
  end

  endpoint :netzke_load do |params, this|
  end

  def eval_form_items(items)
    case items
    when Array
      items.map {|x| eval_form_items(x)}
    when Hash
      items.each_with_object({}) { |(key, value), result|
        result[key] = eval_form_items(value)
      }
    when String
      items.starts_with?(':') ? items[1..-1].to_sym : items
    when Class
      raise "bad value in form #{items}" unless
        items < Delorean::BaseModule::BaseClass

      attrs = @engine.enumerate_attrs_by_node(items)

      @engine.evaluate_attrs_hash(items, attrs, {})
    else
      raise "bad value in form #{items}"
    end
  end

  def configure(c)
    super

    if session[:selected_script_id].nil? || session[:selected_node].nil?
      c.title = "No Report selected."
      return
    end

    begin
      @engine = Marty::ScriptSet.get_engine(session[:selected_script_id])
      raise @engine.to_s if @engine.is_a?(Hash)
      selected_ver = Marty::Script.
        find_by_id(session[:selected_script_id]).version
      script_name  = Marty::Script.
        find_by_id(session[:selected_script_id]).name
      latest_ver   = Marty::Script.
        where("name = ? and obsoleted_dt = 'infinity'",
              script_name)[0].version
      version = selected_ver.match(/^#{latest_ver}$/) ? nil : selected_ver

      items, title, format = @engine.
        evaluate_attrs(session[:selected_node], ["form", "title", "format"], {})

      raise "bad form items" unless items.is_a?(Array)
      raise "bad format" unless ["csv", "xlsx"].member?(format)

    rescue => exc
      c.title = "ERROR"
      c.items = [
                 {
                   field_label: 'Exception',
                   xtype: 	:displayfield,
                   name: 	'displayfield1',
                   value: 	"<span style=\"color:red;\">#{exc}</span>"
                 },
                ]
      return
    end

    items = Marty::Xl.symbolize_keys(eval_form_items(items), ':')

    items = [{html: "<br><b>No input is needed for this report.</b>"}] if
      items.empty?

    self.filename = version.nil? ? title.to_s : "#{title}_#{version}"
    c.title = "Generate: #{title}"
    c.title += "-#{version}" if version
    c.items = items
    c.repformat = format
  end
end

ReportForm = Marty::ReportForm
