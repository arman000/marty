class Marty::Aws::Apigateway::ApiUsagePlanKeyView < Marty::Aws::Grid
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
    c.title      = "Keys - Remote"
    c.attributes = ATTRIBUTES.keys
  end

  def default_bbar
    []
  end
end

AwsApigatewayApiUsagePlanKeyView = Marty::Aws::Apigateway::ApiUsagePlanKeyView
