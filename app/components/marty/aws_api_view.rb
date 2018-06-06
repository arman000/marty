class Marty::AwsApiView < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super

    c.header = false
    c.layout = 'border'
    c.items  =
      [
        :aws_apigateway_api_view,
        :aws_apigateway_api_stage_view,
        :aws_apigateway_api_usage_plan_view,
        :aws_apigateway_api_usage_plan_key_view,
        :aws_api_key_view,
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

  component :aws_apigateway_key_view do |c|
    c.klass      = Marty::AwsApigatewayKeyView
    c.split      = true
    c.region     = :south
    c.width      = '50%'
  end

  component :aws_apigateway_api_stage_view do |c|
    c.klass      = Marty::AwsApigatewayApiStageView
    c.split      = true
    c.region     = :center
    c.width      = '30%'
  end

  component :aws_apigateway_api_usage_plan_view do |c|
    c.klass      = Marty::AwsApigatewayApiUsagePlanView
    c.split      = true
    c.region     = :east
    c.width      = '20%'
  end

  component :aws_apigateway_api_usage_plan_key_view do |c|
    c.klass      = Marty::AwsApigatewayApiUsagePlanKeyView
    c.split      = true
    c.region     = :east
    c.width      = '20%'
  end

  component :aws_api_key_view do |c|
    c.klass      = Marty::AwsApiKeyView
    c.split      = true
    c.region     = :east
    c.width      = '20%'
  end
end

AwsApiView = Marty::AwsApiView
