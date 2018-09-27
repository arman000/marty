class Marty::Aws::Apigateway::ApiKeyMoveView <
      Marty::Aws::Apigateway::ApiUsagePlanView

  include Marty::Extras::Layout

  def configure(c)
    super
    c.prevent_header = true
  end

  client_class do |c|
    c.init_component = l(<<-JS)
    function() {
      var me = this;
      me.callParent();

      var a = this.findComponent('aws_apigateway_api_key_view');
      var u = this.findComponent('aws_apigateway_api_usage_plan_view');

      this.serverConfig              = u.serverConfig;
      this.serverConfig['parent_id'] = a.serverConfig.selected;
    }
    JS

    c.close_window = l(<<-JS)
    function() {
      this.up('window').close();
    }
    JS

    c.reload_parent = l (<<-JS)
    function() {
      var comp = this.findComponent('aws_apigateway_api_key_view');
      console.log(comp);
      comp.reload();
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
    api_key    = Marty::ApiAuth.find(client_config['parent_id'])
    api_key.move_aws_key(usage_plan.aid)
    client.reload_parent
    client.close_window
  end

  endpoint :get_objects do
    # do not fetch new objects
  end

  action :do_move do |a|
    a.text     = "Commit"
    a.icon_cls = "fa fa-truck glyph"
    a.tooltip  = "Commit Key Move"
    a.disabled = true
  end

  def default_bbar
    [:do_move]
  end
end
