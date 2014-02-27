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
         var id = record.get('id');
         me.selectTag({tag_id: id});
         var script_store = me.netzkeGetComponent('script_grid').getStore();
         script_store.load();
         script_store.on('load', function(self, params) {
            script_grid.getSelectionModel().select(0);
            var sel = script_grid.getSelectionModel().getSelection()[0];
            var id = sel && sel.data.id;
            me.selectScript({script_id: id});
            nodename.reset();
            nodename.store.load({params: {}});
         }, me);
      }, me);

      script_grid.on('itemclick', function(script_grid, record) {
         var id = record.get('id');
         me.selectScript({script_id: id});
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
    sset = Marty::ScriptSet.new session[:selected_tag_id]
    engine = sset.get_engine(session[:selected_script_id])

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

  endpoint :select_node do |params, this|
    session[:selected_node] = params[:node]
    this.parent_select_report
  end

  endpoint :select_script do |params, this|
    session[:selected_script_id] = params[:script_id]
  end

  endpoint :select_tag do |params, this|
    session[:selected_tag_id] = params[:tag_id]

    # when we select a new tag, invalidate the script selection
    # FIXME: is this right????
    session[:selected_script_id] = nil
  end

end

SelectReport = Marty::SelectReport
