class Marty::AwsApigatewayAuthorizerView < Marty::AwsGrid
  aws_model('apigateway', 'authorizer')

  def child_components
    [:aws_cognito_view]
  end

  ATTRIBUTES = {
    aid:  {type: :string},
    name: {type: :boolean},
    type: {type: :string},
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  def configure(c)
    super
    c.title      = "AWS API Authorizers"
    c.attributes = ATTRIBUTES.keys
  end
end

AwsApigatewayAuthorizerView = Marty::AwsApigatewayAuthorizerView
