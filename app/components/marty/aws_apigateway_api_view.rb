class Marty::AwsApigatewayApiView < Marty::AwsGrid
  aws_model('apigateway', 'api')

  def child_components
    [:aws_apigateway_authorizer_view,
     :aws_apigateway_api_stage_view,
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

  def configure(c)
    super
    c.title      = "AWS REST APIs"
    c.attributes = ATTRIBUTES.keys
    c.flex = 2
  end
end

AwsApigatewayApiView = Marty::AwsApigatewayApiView
