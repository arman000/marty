class Marty::AwsApiUserView < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super

    c.header = false
    c.layout = 'border'
    c.items  =
      [
        :aws_apigateway_api_view,
        :aws_apigateway_authorizer_view,
        :aws_cognito_view,
      ]
  end

  component :aws_apigateway_api_view do |c|
    c.klass      = Marty::AwsApigatewayApiView
    c.split      = true
    c.region     = :west
    c.width      = '30%'
    c.height     = '50%'
    c.scrollable = true
  end

  component :aws_apigateway_authorizer_view do |c|
    c.klass      = Marty::AwsApigatewayAuthorizerView
    c.split      = true
    c.region     = :center
    c.width      = '20%'
    c.scrollable = true
  end

  component :aws_cognito_view do |c|
    c.klass      = Marty::AwsCognitoView
    c.split      = true
    c.region     = :east
    c.width      = '50%'
    c.scrollable = true
  end
end

AwsApiUserView = Marty::AwsApiUserView
