class Marty::Aws::ApigatewayApiUsagePlanView < Marty::Aws::Grid
  aws_model('apigateway', 'usage_plan')

  def child_components
    [:aws_apigateway_api_usage_plan_key_view,
     :aws_api_key_view
    ]
  end

  ATTRIBUTES = {
    aid:  {type: :string},
    name: {type: :string}
  }

  NESTED_THROTTLE_ATTRIBUTES = {
    burst_limit: {type: :string},
    rate_limit:  {type: :string},
  }

  NESTED_QUOTA_ATTRIBUTES = {
    limit:  {type: :string},
    offset: {type: :string},
    period: {type: :string}
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  NESTED_THROTTLE_ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value, ['throttle'])
  end

  NESTED_QUOTA_ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value, ['quota'])
  end

  def configure(c)
    super
    c.title      = "AWS API Key Usage Plans"
    c.attributes = ATTRIBUTES.keys +
                   NESTED_THROTTLE_ATTRIBUTES.keys +
                   NESTED_QUOTA_ATTRIBUTES.keys
  end

  client_class do |c|
    c.netzke_on_do_delete_usage_plan = l(<<-JS)
    function() {
      this.server.destroyUsagePlan();
    }
    JS
  end

  def default_bbar
    [:do_delete_usage_plan]
  end

  action :do_delete_usage_plan do |a|
    a.text     = "Delete"
    a.icon_cls = "fa fa-trash glyph"
    a.disabled = true
  end

  endpoint :destroy_usage_plan do
    begin
      usage_plan = Marty::Aws::Object.find(client_config['selected'])
      Marty::Aws::Apigateway.new.delete_usage_plan(usage_plan.value['aid'])
      usage_plan.delete
      client.reload
    rescue => e
      client.netzke_notify e.message
    end
  end
end

AwsApigatewayApiUsagePlanView = Marty::Aws::ApigatewayApiUsagePlanView
