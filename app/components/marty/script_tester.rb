class Marty::ScriptTester < Marty::Form
  include Marty::Extras::Layout

  def configure(c)
    super

    c.items =
      [
        fieldset(I18n.t("script_tester.attributes"),
                 {
                   name:         "attrs",
                   xtype:        :textarea,
                   value:        "",
                   hide_label:   true,
                   min_height:   125,
                 },
                 {},
                ),
        fieldset(I18n.t("script_tester.parameters"),
                 {
                   name:         "params",
                   xtype:        :textarea,
                   value:        "",
                   hide_label:   true,
                   min_height:   125,
                 },
                 {},
                ),
        :result,
      ]
  end

  client_class do |c|
    c.include :script_tester
  end

  def new_engine
    return unless root_sess[:selected_script_name]

    Marty::ScriptSet.new(root_sess[:selected_tag_id]).
      get_engine(root_sess[:selected_script_name])
  end

  endpoint :submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    attrs = data["attrs"].split(';').map(&:strip).reject(&:empty?)

    pjson = data["params"].split("\n").map(&:strip).reject(&:empty?).map do |s|
              s.sub(/^([a-z0-9_]*)\s*=/, '"\1": ')
    end.join(',')

    begin
      phash = ActiveSupport::JSON.decode("{ #{pjson} }")
    rescue MultiJson::DecodeError
      client.netzke_notify "Malformed input parameters"
      return
    end

    engine = new_engine

    begin
      result = attrs.map do |a|
        node, attr = a.split('.')
        raise "bad attribute: '#{a}'" if !attr

        # Need to clone phash since it's modified by eval.  It can
        # be reused for a given node but not across nodes.
        res = engine.evaluate(node, attr, phash.clone)
        q = CGI::escapeHTML(res.to_json)
        "#{a} = #{q}"
      end

      client.netzke_notify "done"
      client.set_result result.join("<br/>")
    rescue SystemStackError
      return client.netzke_notify "System Stack Error"
    rescue => exc
      res = Delorean::Engine.grok_runtime_exception(exc)

      result = ["Error: #{res['error']}", "Backtrace:"] +
        res["backtrace"].map { |m, line, fn| "#{m}:#{line} #{fn}" }

      client.netzke_notify "failed"
      client.set_result '<font color="red">' + result.join("<br/>") + "</font>"
    end
  end

  action :apply do |a|
    a.text     = I18n.t("script_tester.compute")
    a.tooltip  = I18n.t("script_tester.compute")
    a.icon_cls = "fa fa-bug glyph"
    a.disabled = false
  end

  component :result do |c|
    c.klass       = Marty::Panel
    c.title       = I18n.t("script_tester.results")
    c.html        = ""
    c.flex        = 1
    c.min_height  = 250
    c.auto_scroll = true
  end
end

ScriptTester = Marty::ScriptTester
