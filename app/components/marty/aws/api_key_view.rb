class Marty::Aws::ApiKeyView < Marty::Grid
  include Marty::Extras::Layout
  has_marty_permissions create: :admin,
                        read:   :admin,
                        delete: :admin

  def child_components
    [:aws_apigateway_api_key_move_window]
  end

  def configure(c)
    super

    c.paging = :buffered
    c.editing = :in_form
    c.title   = 'Marty AWS API KEYS (local)'
    c.model   = 'Marty::Aws::ApiKey'
    c.attributes = [
      :id,
      :aid,
      :api_id,
      :api_usage_plan_id,
      :name,
      :api_key,
      :username,
      :email,
    ]
  end

  [:aid, :api_id, :api_usage_plan_id].each do |a|
    attribute a do |c|
      c.hidden = true
    end
  end

  def get_records params
    api_id            = client_config['api_id']
    api_usage_plan_id = client_config['parent_id']

    a_aid  = Marty::Aws::Object.find(api_id).value['aid'] rescue nil
    up_aid = Marty::Aws::Object.find(api_usage_plan_id).value['aid'] rescue nil

    model.where(api_id: a_aid, api_usage_plan_id: up_aid).scoping do
      super
    end
  end

  client_class do |c|
    c.netzke_on_do_generate = l(<<-JS)
    function(params) {
      this.server.generateApiKey();
    }
    JS

    c.reload = l(<<-JS)
    function(opts={}) {
      var parent = this.netzkeGetParentComponent();

      var api = parent.netzkeGetComponent('aws_apigateway_api_view');
      this.serverConfig['api_id'] = api.serverConfig['selected'];

      this.callParent();
    }
    JS

    c.reload_parent = l(<<-JS)
    function() {
      var p = this.netzkeGetParentComponent();
      var c = p &&
              p.netzkeGetComponent('aws_apigateway_api_usage_plan_key_view')

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

  action :do_generate do |a|
    a.text     = 'Generate'
    a.icon_cls = "fa fa-key glyph"
  end

  action :do_move do |a|
    a.text     = 'Move'
    a.icon_cls = "fa fa-truck glyph"
    a.disabled = true
  end

  endpoint :generate_api_key do
    api_id            = client_config['api_id']
    api_usage_plan_id = client_config['parent_id']

    return client.netzke_notify "Usage plan not selected" unless api_id &&
                                                                 api_usage_plan_id

    begin
      api                = Marty::Aws::Object.find(api_id)
      api_usage_plan_aid = Marty::Aws::Object.find(api_usage_plan_id).value['aid']

      seq = ActiveRecord::Base.connection.execute(
        "SELECT last_value FROM marty_aws_api_keys_id_seq").first['last_value']

        api_auth = Marty::ApiAuth.create(
          app_name:    "External Client #{seq}",
          script_name: api.value['name']
        )

        Marty::Aws::ApiKey.create(
          api_auth_id:       api_auth.id,
          api_id:            api.value['aid'],
          api_usage_plan_id: api_usage_plan_aid,
        )
    rescue => e
      client.netzke_notify e.message
    end
    client.reload_parent
    client.reload
  end

  endpoint :destroy do |data|
    super(data)
    client.reload_parent
  end

  def default_bbar
    [:do_generate, :do_move, :delete]
  end

  component :aws_apigateway_api_key_move_window do |c|
    c.klass = Marty::Aws::ApigatewayApiKeyMoveWindow
  end
end

AwsApiKeyView = Marty::Aws::ApiKeyView
