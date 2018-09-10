class Marty::Aws::ApigatewayApiKeyMoveView < Marty::Aws::ApigatewayApiUsagePlanView
  include Marty::Extras::Layout

  def configure(c)
    super
    c.model = "Marty::AwsObject"
    c.prevent_header = true
  end

  client_class do |c|
    c.init_component = l(<<-JS)
    function() {
      var me = this;
      me.callParent();
      //this.getStore().suspendEvents();

      var w  = this.netzkeGetParentComponent();
      var p  = w.netzkeGetParentComponent();
      var up = p.netzkeGetComponentFromParent(
               'aws_apigateway_api_usage_plan_view');

      this.serverConfig = up.serverConfig;
      this.serverConfig['parent_id'] = p.serverConfig.selected;
    }
    JS

    c.close_window = l(<<-JS)
    function() {
      this.up('window').close();
    }
    JS

    c.reload_parent = l (<<-JS)
    function() {
      var window      = this.netzkeGetParentComponent();
      var parent_view = window.netzkeGetParentComponent();
      parent_view.reload();
    }
    JS

    c.netzke_on_do_move = l(<<-JS)
    function() {
      this.server.moveKey();
    }
    JS
  end

  endpoint :move_key do
    usage_plan = Marty::Aws::Object.find(client_config['selected'])
    api_key    = Marty::Aws::ApiKey.find(client_config['parent_id'])
    api_key.move_key(usage_plan.value['aid'])
    client.reload_parent
    client.close_window
  end

  endpoint :get_objects do
    # do not fetch new objects
  end

  action :do_move do |a|
    a.text     = "Commit"
    a.icon_cls = "fa fa-truck glyph"
    a.disabled = true
  end

  def default_bbar
    [:do_move]
  end
end
