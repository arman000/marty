class Marty::SelectReport < Marty::CmFormPanel
  include Marty::Extras::Layout

  component :script_list do |c|
    c.height 		= 300
    c.klass 		= Marty::ScriptGrid
    c.title 		= I18n.t("script.selection_list")
    c.bbar 		= []
    c.columns     	= [:name, :version]
    c.scope 		= ["obsoleted_dt = 'infinity' AND name like '%Report'"]
  end

  component :script_log do |c|
    c.klass 		= Marty::ScriptLogGrid
    c.height 		= 200
    c.load_inline_data 	= false
    c.group_id 	 	= session[:selected_group_id]
    c.script_id 	= session[:selected_script_id]
    c.title 		= I18n.t("script.selection_history")
    c.columns 	 	= [:version, :last_update]
  end

  ######################################################################

  def configure(c)
    super

    c.items = [
               :script_list,
               :script_log,
               fieldset(I18n.t("reporting.select_report"),
                        {
                          xtype: 	 :netzkeremotecombo,
                          name: 	 "nodename",
                          attr_type: 	 :string,
                          virtual: 	 true,
                          hide_label:	 true,
                          width: 	 200,
                        },
                        {},
                        ),
              ]
    c.bbar = []
  end

  js_configure do |c|
    c.header = false

    c.init_component = <<-JS
      function() {
	var me = this;
      	me.callParent();

	var form = me.getForm();
	var nodename = form.findField('nodename');
      	var script_list = me.netzkeGetComponent('script_list').getView();
      	var script_log = me.netzkeGetComponent('script_log').getView();
      	script_list.on('itemclick', function(script_list, record) {
	  var id = record.get('id');
          me.selectScript({script_id: id});
          var log_store = me.netzkeGetComponent('script_log').getStore();
          log_store.load();
          log_store.on('load', function(self, params) {
            script_log.getSelectionModel().select(0);
            var sel = script_log.getSelectionModel().getSelection()[0];
            var id = sel && sel.data.id;
            me.selectLog({log_id: id});
            nodename.reset();
            nodename.store.load({params: {}});
          }, me);
      	}, me);

      	var script_log = me.netzkeGetComponent('script_log').getView();
      	script_log.on('itemclick', function(script_log, record) {
	  var id = record.get('id');
          me.selectLog({log_id: id});
	  nodename.reset();
	  nodename.store.load({params: {}});
        }, me);

      	nodename.on('select', function(combo, record) {
          var data = record[0] && record[0].data;
	  me.selectNode({node: data.value});
	});

      }
      JS

    c.get_current_state = <<-JS
      function() {
	var me = this;
	var form = me.getForm();
	var o = Object();

      	var script_log = me.netzkeGetComponent('script_log').getView();
	var sel = script_log.getSelectionModel().getSelection()[0];
	o.script_id = sel && sel.data.id;

	o.nodename = form.findField('nodename').getDisplayValue();
	return o;
      }
      JS

    c.parent_select_report = <<-JS
      function() {
	this.netzkeGetParentComponent().selectReport();
      }
      JS
  end

  # FIXME: should be in a library
  REPORT_ATTR_SET = Set["title", "form", "result", "format"]

  def node_list
    engine = Marty::ScriptSet.get_engine(session[:selected_script_id])
    return [] unless engine

    nodes = engine.enumerate_nodes.select { |n|
      attrs = Set.new(engine.enumerate_attrs_by_node(n))
      attrs.superset? REPORT_ATTR_SET
    }

    nodes.map { |node|
      begin
        title, format = engine.evaluate_attrs(node, ["title", "format"])
        format ? [node, "#{title} (#{format})"] : nil
      rescue
        [node, node]
      end
    }.compact.sort
  end

  endpoint :get_combobox_options do |params, this|
    this.data = node_list if params["attr"] == "nodename"
  end

  ######################################################################

  endpoint :select_node do |params, this|
    session[:selected_node] = params[:node]
    this.parent_select_report
  end

  endpoint :select_script do |params, this|
    # store selected script id in the session for this component's instance
    script = Marty::Script.find_by_id(params[:script_id])

    session[:selected_group_id] = script && script.group_id
    session[:selected_script_id] = params[:script_id]
  end

  endpoint :select_log do |params, this|
    # store selected script id in the session for this component's instance
    session[:selected_script_id] = params[:log_id]
  end

end

SelectReport = Marty::SelectReport
