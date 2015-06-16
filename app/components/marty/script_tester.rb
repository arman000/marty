class Marty::ScriptTester < Marty::Form
  include Marty::Extras::Layout

  def configure(c)
    super

    c.items =
      [
       fieldset(I18n.t("script_tester.attributes"),
=begin
                {
                  xtype:        :netzkeremotecombo,
                  name:         "nodename",
                  attr_type:    :string,
                  virtual:      true,
                  field_label:  "Node",
                },
                {
                  xtype:        :netzkeremotecombo,
                  name:         "attrname",
                  attr_type:    :string,
                  virtual:      true,
                  field_label:  "Attribute",
                },
=end
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
=begin
                {
                  xtype:        :netzkeremotecombo,
                  name:         "paramname",
                  attr_type:    :string,
                  virtual:      true,
                  hide_label:   true,
                },
=end
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
=begin
    c.select_script = <<-JS
    function(script_name) {
       console.log("selecting the script for the tester");
       var me = this;

       var form = me.getForm();
       // reload the attr/param drop downs
       form.findField('nodename').reset()
       form.findField('nodename').store.load({params: {}});
       form.findField('attrname').reset();
       form.findField('attrname').store.load({params: {}});
       form.findField('paramname').store.load({params: {}});
    }
    JS

    c.init_component = <<-JS
    function() {
       var me = this;
       me.callParent();
       var form = me.getForm();

       var nodename  = form.findField('nodename');
       var attrname  = form.findField('attrname');
       var attrs     = form.findField('attrs');
       var paramname = form.findField('paramname');
       var params    = form.findField('params');

       nodename.on('select', function(combo, record) {
          console.log('node on select');
          if(record instanceof Array) {
             record = record[0]
          }
          var data = record && record.data;
          me.selectNode({node: data.text});
          attrname.reset();
          attrname.store.load({params: {}});
       });

       attrname.on('select', function(combo, record) {
          if (nodename.getValue()) {
             if(record instanceof Array) {
                record = record[0]
             }
             attrs.setValue(attrs.getValue() +
                nodename.getDisplayValue() + "." + record.data.text + '; ');
          }
          combo.select(null);
       });

       paramname.on('select', function(combo, record) {
          if(record instanceof Array) {
             record = record[0]
          }
          params.setValue(params.getValue() + record.data.text + " = 0\\n");
          combo.select(null);
       });
    }
    JS
=end

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

=begin
  def node_list
    engine = new_engine
    engine ? engine.enumerate_nodes.sort : []
  end

  def attr_list
    engine = new_engine
    node = root_sess[:selected_node]
    node && engine ? engine.enumerate_attrs_by_node(node).sort : []
  end

  def param_list
    engine = new_engine
    engine ? engine.enumerate_params.sort : []
  end
=end

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

=begin
  def combofy(l)
    l.each_with_index.map {|x, i| [i+1, x]}
  end

  endpoint :select_node do |params, this|
    root_sess[:selected_node] = params[:node]
  end

  endpoint :get_combobox_options do |params, this|
    this.data = case params["attr"]
                when "nodename" then
                  combofy(node_list)
                when "attrname" then
                  combofy(attr_list)
                when "paramname"
                  combofy(param_list)
                end
  end
=end

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
