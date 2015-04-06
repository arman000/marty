class Marty::ReportSelect < Marty::Form
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
    c.height           = 350
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
       fieldset(I18n.t("reporting.report_select"),
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
       var nodename    = me.getForm().findField('nodename');

       nodename.on('select', function(self, record) {
          var data = record[0] && record[0].data;
          me.selectNode({node: data.value});
       });

       tag_grid.getSelectionModel().on('selectionchange',
        function(self, records) {
          var tag_id = records[0].get('id');
          me.selectTag({tag_id: tag_id});
          script_grid.getStore().load();
       }, me);

       script_grid.getSelectionModel().on('selectionchange',
        function(self, records) {
          if(script_grid.getStore().isLoading() == true) return;

          if(records[0] == null)
             return;

          var script_name = records[0].get('name');
          me.selectScript({script_name: script_name});
          nodename.reset();
          nodename.store.load({params: {}});
          }, me);
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
      roles = engine.evaluate(node, "roles") rescue nil
      next if roles && !roles.any?{ |r| Marty::User.has_role(r) }

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

ReportSelect = Marty::ReportSelect
