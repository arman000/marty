class Marty::AwsApigatewayApiUsagePlanKeyView < Marty::AwsGrid
  aws_model('apigateway', 'usage_plan_key')

  ATTRIBUTES = {
    aid:   {type: :string},
    name:  {type: :string},
    value: {type: :string},
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  def configure(c)
    super
    c.title      = "AWS API Usage Plan Keys"
    c.attributes = ATTRIBUTES.keys
  end
end

AwsApigatewayApiUsagePlanKeyView = Marty::AwsApigatewayApiUsagePlanKeyView
