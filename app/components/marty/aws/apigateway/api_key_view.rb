class Marty::Aws::Apigateway::ApiKeyView < Marty::ApiAuthView
  include Marty::Extras::Layout
  has_marty_permissions create: :admin,
                        read:   :admin,
                        delete: :admin

  def child_components
    [:aws_apigateway_api_key_move_window]
  end

  def configure(c)
    super

    c.paging = :pagination
    c.editing = :in_form
    c.title   = 'Keys - Local'
    c.attributes = [
      :aid,
      :api_key,
      :app_name,
      :username,
      :email,
      :api_id,
      :api_usage_plan_id,
    ]
  end

  [:username, :email].each do |a|
    attribute a do |c|
      c.getter = lambda {|r| r.parameters['aws_api_key'][a.to_s]}
    end
  end

  [:aid, :api_id, :api_usage_plan_id].each do |a|
    attribute a do |c|
      c.getter = lambda {|r| r.parameters['aws_api_key'][a.to_s]}
      c.hidden = true
    end
  end

  def get_records params
    api_id            = client_config['api_id']
    api_usage_plan_id = client_config['parent_id']

    a_aid  = Marty::Aws::Object.find(api_id).aid            rescue nil
    up_aid = Marty::Aws::Object.find(api_usage_plan_id).aid rescue nil

    query = "parameters->'aws_api_key'->>'api_id' = ? "\
            "AND parameters->'aws_api_key'->>'api_usage_plan_id' = ?"

    Marty::ApiAuth.where(obsoleted_dt: 'infinity').
      where(query, a_aid, up_aid).scoping do
      super
    end
  end

  client_class do |c|
    c.parent_generate = l(<<-JS)
    function(params) {
      var me = this;
      Ext.Msg.show({
        title: 'Generate API Key',
        msg: 'Enter Client app name that will be associated with API key',
        width: 375,
        buttons: Ext.Msg.OKCANCEL,
        prompt: true,
        fn: function (btn, value, cfg) {
          btn == "ok" && me.server.generateApiKey(value);
        }
      });
    }
    JS

    c.reload = l(<<-JS)
    function(opts={}) {
      var api = this.findComponent('aws_apigateway_api_view');
      this.serverConfig['api_id'] = api.serverConfig['selected'];
      this.callParent();
    }
    JS

    c.reload_linked = l(<<-JS)
    function() {
      var c = this.findComponent('aws_apigateway_api_usage_plan_key_view')
      if (c) { c.reload() }
    }
    JS

    c.netzke_on_do_move = l(<<-JS)
    function() {
      this.netzkeLoadComponent("aws_apigateway_api_key_move_window",
        { callback: function(w) {w.show(); },
      });
    }
    JS
  end

  action :parent_generate do |a|
    a.text     = 'Generate'
    a.icon_cls = "fa fa-key glyph"
    a.handler  = :parent_generate
    a.disabled = true
  end

  action :do_move do |a|
    a.text     = 'Move'
    a.icon_cls = "fa fa-truck glyph"
    a.disabled = true
  end

  endpoint :generate_api_key do |app_name|

    api_id            = client_config['api_id']
    api_usage_plan_id = client_config['parent_id']

    return client.netzke_notify "Usage plan not selected" unless api_id &&
                                                                 api_usage_plan_id

    begin
      api                = Marty::Aws::Object.find(api_id)
      api_usage_plan_aid = Marty::Aws::Object.find(api_usage_plan_id).aid

      # derive script from api name by convention
      script = api.name.split('-').drop(1).map{|s| s.capitalize}.join

      api_auth = Marty::ApiAuth.create!(
        app_name:    app_name,
        script_name: script,
      )

      api_auth.create_aws_api_key(api.aid, api_usage_plan_aid)
    rescue => e
      client.netzke_notify e.message
    end
    client.reload
    client.reload_linked
  end

  endpoint :destroy do |data|
    super(data)
    client.reload_linked
  end

  def default_bbar
    [:parent_generate, :do_move, :delete]
  end

  component :aws_apigateway_api_key_move_window do |c|
    c.klass = Marty::Aws::Apigateway::ApiKeyMoveWindow
  end
end

AwsApigatewayApiKeyView = Marty::Aws::Apigateway::ApiKeyView
