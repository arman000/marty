class Marty::Aws::ApigatewayApiAuthorizerStageView < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super

    c.header = false
    c.layout = 'border'
    c.items  =
      [
        :aws_apigateway_authorizer_view,
        :aws_apigateway_api_stage_view,
      ]
    c.height = 300
  end

  component :aws_apigateway_authorizer_view do |c|
    c.klass      = Marty::Aws::ApigatewayAuthorizerView
    c.split      = true
    c.region     = :south
    c.scrollable = true
  end

  component :aws_apigateway_api_stage_view do |c|
    c.klass      = Marty::Aws::ApigatewayApiStageView
    c.split      = true
    c.region     = :south
  end
end

AwsApigatewayApiAuthorizerView = Marty::Aws::ApigatewayApiAuthorizerStageView
