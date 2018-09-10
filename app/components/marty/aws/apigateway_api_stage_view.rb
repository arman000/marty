class Marty::Aws::ApigatewayApiStageView < Marty::Aws::Grid
  aws_model('apigateway', 'stage')

  ATTRIBUTES = {
    created_date:      {type: :datetime, label: 'Created Date'},
    deployment_id:     {type: :string},
    description:       {type: :string},
    stage_name:        {type: :string, label: 'Name'},
    last_updated_date: {type: :datetime, label: 'Last Updated Date'}
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  def configure(c)
    super
    c.title      = "AWS API Stages"
    c.attributes = ATTRIBUTES.keys
  end

  def default_bbar
    [:create, :deploy]
  end

  action :create do |c|
    c.icon_cls = "fa fa-plus glyph"
  end

  action :deploy do |c|
    c.icon_cls = "fa fa-upload glyph"
  end

  client_class do |c|
    c.netzke_on_do_export_swagger = l(<<-JS)
    function() {
      var stage_rec_id = this.serverConfig.selected;
      var api_rec_id   = this.netzkeGetComponentFromParent(
                         'aws_apigateway_api_view').getSelection()[0].getId();

      this.server.exportSwagger({
        'api_rec_id'   : api_rec_id,
        'stage_rec_id' : stage_rec_id
        });
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

  action :do_export_swagger do |a|
    a.text     = "Export Swagger"
    a.icon_cls = "fa fa-file-export glyph"
    a.disabled = true
  end

  action :do_create_usage_plan do |a|
    a.text     = "Create Usage Plan"
    a.icon_cls = "fa fa-plus glyph"
    a.disabled = true
  end

  def default_bbar
    [:do_export_swagger, :do_create_usage_plan]
  end

  endpoint :export_swagger do |params|
    begin
      api_aid    = Marty::Aws::Object.find(params['api_rec_id']).value['aid']
      stage_name = Marty::Aws::Object.find(params['stage_rec_id']).
                     value['stage_name']

      resp = Marty::Aws::Apigateway.new.swagger_export(api_aid, stage_name)
      client.show_json(resp.body)
    rescue => e
      client.netzke_notify e.message
    end
  end

  component :aws_apigateway_usage_plan_window do |c|
    c.klass = Marty::Aws::ApigatewayUsagePlanWindow
  end
end

AwsApigatewayApiStageView = Marty::Aws::ApigatewayApiStageView
