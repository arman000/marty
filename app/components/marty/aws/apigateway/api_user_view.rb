class Marty::Aws::Apigateway::ApiUserView < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super

    c.layout = 'border'
    c.header = false
    c.items =
      [
        {
          component: :aws_apigateway_api_view,
          region: :west,
          border: true,
          width: '40%'
        },
        {
          component: :aws_apigateway_authorizer_view,
          region: :center,
          border: true,
          width: '20%'
        },
        {
          component: :aws_cognito_pool_view,
          region: :east,
          border: true,
          width: '40%'
        },
      ]

  end

  component :aws_apigateway_api_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiView
  end

  component :aws_apigateway_authorizer_view do |c|
    c.klass = Marty::Aws::Apigateway::AuthorizerView
  end

  component :aws_cognito_pool_view do |c|
    c.klass = Marty::Aws::Cognito::PoolView
  end
end

AwsApigatewayApiUserView = Marty::Aws::Apigateway::ApiUserView
