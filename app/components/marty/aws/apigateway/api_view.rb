class Marty::Aws::Apigateway::ApiView < Marty::Aws::Grid
  aws_model('apigateway', 'api')

  def child_components
    [:aws_apigateway_authorizer_view,
     :aws_apigateway_api_usage_plan_view,
    ]
  end

  ATTRIBUTES = {
    aid:          {type: :string},
    name:         {type: :boolean},
    description:  {type: :string},
    created_date: {type: :datetime, label: 'Created Date'},
    version:      {type: :string},
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  client_class do |c|
    c.netzke_on_do_export_swagger = l(<<-JS)
    function() {
      this.server.exportSwagger();
    }
    JS

    c.netzke_on_do_create_usage_plan = l(<<-JS)
    function() {
      this.netzkeLoadComponent("aws_apigateway_usage_plan_window",
        { callback: function(w) {w.show(); },
        });
    }
    JS

    c.show_json = l(<<-JS)
    function(json) {
       Ext.create('Ext.Window', {
         layout:        "fit",
         height:        400,
         autoWidth:     true,
         modal:         true,
         autoScroll:    true,
         html:          json,
         title:         "Swagger Export Response"
      }).show();
    }
    JS

    c.reload = l (<<-JS)
    function() {
      this.callParent();

      // reload api key usage plans on api stage view actions
      var usage_plan_view = this.netzkeGetComponentFromParent(
                            'aws_apigateway_api_usage_plan_view');
      if (usage_plan_view) { usage_plan_view.reload()}
    }
    JS
  end

  def configure(c)
    super
    c.title      = 'API'
    c.attributes = ATTRIBUTES.keys
  end

  action :do_export_swagger do |a|
    a.text     = "Swagger"
    a.icon_cls = "fa fa-file-export glyph"
    a.disabled = true
  end

  action :do_create_usage_plan do |a|
    a.text     = "New Usage Plan"
    a.icon_cls = "fa fa-plus glyph"
    a.disabled = true
  end

  endpoint :export_swagger do
    begin
      api_aid = Marty::Aws::Object.find(client_config['selected']).aid
      resp = Marty::Aws::Apigateway.new.swagger_export(api_aid)
      client.show_json(resp.body)
    rescue => e
      client.netzke_notify e.message
    end
  end

  def default_bbar
    [:do_create_usage_plan, :do_export_swagger]
  end

  component :aws_apigateway_usage_plan_window do |c|
    c.klass = Marty::Aws::Apigateway::UsagePlanWindow
  end
end

AwsApigatewayApiView = Marty::Aws::Apigateway::ApiView
