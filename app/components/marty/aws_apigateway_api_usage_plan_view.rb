class Marty::AwsApigatewayApiUsagePlanView < Marty::AwsGrid
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
end

AwsApigatewayApiUsagePlanView = Marty::AwsApigatewayApiUsagePlanView
