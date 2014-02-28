class Marty::SelectReport < Marty::CmFormPanel
  include Marty::Extras::Layout

  component :tag_grid do |c|
    c.klass            = Marty::TagGrid
    c.height           = 200
    c.load_inline_data = false
    c.title            = I18n.t("script.selection_history")
    c.columns          = [:name, :created_dt, :comment]
    c.bbar             = []
  end

  component :script_grid do |c|
    c.height           = 300
    c.klass            = Marty::ScriptGrid
    c.title            = I18n.t("script.selection_list")
    c.bbar             = []
    c.columns          = [:name, :tag]
    c.scope            = ["name like '%Report'"]
  end

  ######################################################################

  def configure(c)
    super

    c.items =
      [
       :tag_grid,
       :script_grid,
       fieldset(I18n.t("reporting.select_report"),
                {
                  xtype:        :netzkeremotecombo,
                  name:         "nodename",
                  attr_type:    :string,
                  virtual:      true,
                  hide_label:   true,
                  width:        200,
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

       var tag_grid    = me.netzkeGetComponent('tag_grid').getView();
       var script_grid = me.netzkeGetComponent('script_grid').getView();
       var form        = me.getForm();
       var nodename    = form.findField('nodename');

       tag_grid.on('itemclick', function(tag_grid, record) {
          var tag_id = record.get('id');
          me.selectTag({tag_id: tag_id});
          script_grid.getStore().load();
       }, me);

       script_grid.on('itemclick', function(script_grid, record) {
          var script_name = record.get('name');
          me.selectScript({script_name: script_name});
          nodename.reset();
          nodename.store.load({params: {}});
       }, me);

       nodename.on('select', function(combo, record) {
          var data = record[0] && record[0].data;
          me.selectNode({node: data.value});
       });
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
    sset = Marty::ScriptSet.new root_sess[:selected_tag_id]
    engine = sset.get_engine(root_sess[:selected_script_name])

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
    }.compact.sort{ |a,b| a[1] <=> b[1]}
  end

  endpoint :get_combobox_options do |params, this|
    this.data = node_list if params["attr"] == "nodename"
  end

  ######################################################################

  endpoint :select_tag do |params, this|
    root_sess[:selected_tag_id]      = params[:tag_id]
    root_sess[:selected_script_name] = nil
    root_sess[:selected_node]        = nil
  end

  endpoint :select_script do |params, this|
    root_sess[:selected_script_name] = params[:script_name]
    root_sess[:selected_node]        = nil
  end

  endpoint :select_node do |params, this|
    root_sess[:selected_node]        = params[:node]
    this.parent_select_report
  end
end

SelectReport = Marty::SelectReport
