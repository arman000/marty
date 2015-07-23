class Marty::ScriptTester < Marty::Form
  include Marty::Extras::Layout

  def configure(c)
    super

    c.items =
      [
       fieldset(I18n.t("script_tester.attributes"),
                {
                  name:         "attrs",
                  attr_type:    :text,
                  value:        "",
                  hide_label:   true,
                  min_height:   125,
                },
                {},
                ),
       fieldset(I18n.t("script_tester.parameters"),
                {
                  name:         "params",
                  attr_type:    :text,
                  value:        "",
                  hide_label:   true,
                  min_height:   125,
                },
                {},
                ),
       :result,
      ]
  end

  js_configure do |c|
    c.set_result = <<-JS
    function(html) {
       var result = this.netzkeGetComponent('result');
       result.updateBodyHtml(html);
    }
    JS

  end

  def new_engine
    return unless root_sess[:selected_script_name]

    Marty::ScriptSet.new(root_sess[:selected_tag_id]).
      get_engine(root_sess[:selected_script_name])
  end

  endpoint :netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    attrs = data["attrs"].split(';').map(&:strip).reject(&:empty?)

    pjson = data["params"].split("\n").map(&:strip).reject(&:empty?).map {
      |s| s.sub(/^([a-z0-9_]*)\s*=/, '"\1": ')
    }.join(',')

    begin
      phash = ActiveSupport::JSON.decode("{ #{pjson} }")
    rescue MultiJson::DecodeError
      this.netzke_feedback "Malformed input parameters"
      return
    end

    engine = new_engine

    begin
      result = attrs.map { |a|
        node, attr = a.split('.')
        raise "bad attribute: '#{a}'" if !attr
        # Need to clone phash since it's modified by eval.  It can
        # be reused for a given node but not across nodes.
        res = engine.evaluate(node, attr, phash.clone)
        q = CGI::escapeHTML(res.to_json)
        "#{a} = #{q}"
      }

      this.netzke_feedback "done"
      this.set_result result.join("<br/>")

    rescue SystemStackError
      return this.netzke_feedback "System Stack Error"

    rescue => exc
      res = Delorean::Engine.grok_runtime_exception(exc)

      result = ["Error: #{res['error']}", "Backtrace:"] +
        res["backtrace"].map {|m, line, fn| "#{m}:#{line} #{fn}"}

      this.netzke_feedback "failed"
      this.set_result '<font color="red">' + result.join("<br/>") + "</font>"
    end
  end

  action :apply do |a|
    a.text     = I18n.t("script_tester.compute")
    a.tooltip  = I18n.t("script_tester.compute")
    a.icon     = :script_go
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
