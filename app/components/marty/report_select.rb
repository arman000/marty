class Marty::ReportSelect < Marty::Form
  include Marty::Extras::Layout

  component :tag_grid do |c|
    c.klass            = Marty::TagGrid
    c.height           = 200
    c.load_inline_data = false
    c.title            = I18n.t("script.selection_history")
    c.attributes = [:name, :created_dt, :comment]
    c.bbar             = []
  end

  component :script_grid do |c|
    c.height           = 350
    c.klass            = Marty::ScriptGrid
    c.title            = I18n.t("script.selection_list")
    c.bbar             = []
    c.attributes = [:name, :tag]
    c.scope = lambda { |r|
      r.where("name like '%Report'")
    }
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
    c.bbar = nil
  end

  client_class do |c|
    c.header = false
    c.include :report_select
  end

  # FIXME: should be in a library
  REPORT_ATTR_SET = Set["title", "form", "result", "format"]

  def node_list
    sset = Marty::ScriptSet.new root_sess[:selected_tag_id]
    engine = sset.get_engine(root_sess[:selected_script_name])

    return [] unless engine

    nodes = engine.enumerate_nodes.select do |n|
      attrs = Set.new(engine.enumerate_attrs_by_node(n))
      attrs.superset? REPORT_ATTR_SET
    end

    nodes.map do |node|
      roles = engine.evaluate(node, "roles") rescue nil
      next if roles && !roles.any? { |r| Marty::User.has_role(r) }

      begin
        title, format = engine.evaluate(node, ["title", "format"])
        format ? [node, "#{title} (#{format})"] : nil
      rescue
        [node, node]
      end
    end.compact.sort { |a, b| a[1] <=> b[1] }
  end

  endpoint :get_combobox_options do |params|
    client.data = node_list if params["attr"] == "nodename"
  end

  ######################################################################

  endpoint :select_tag do |params|
    root_sess[:selected_tag_id]      = params[:tag_id]
    root_sess[:selected_script_name] = nil
    root_sess[:selected_node]        = nil
  end

  endpoint :select_script do |params|
    root_sess[:selected_script_name] = params[:script_name]
    root_sess[:selected_node]        = nil
  end

  endpoint :select_node do |params|
    root_sess[:selected_node]        = params[:node]
    client.parent_select_report
  end
end

ReportSelect = Marty::ReportSelect
