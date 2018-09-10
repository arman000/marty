class Marty::Aws::ApiView < Netzke::Base
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
    c.klass       = Marty::Aws::ApigatewayApiView
    c.split       = true
    c.region      = :center
    c.width       = '20%'
    c.scrollable  = true
  end

  component :aws_apigateway_api_stage_view do |c|
    c.klass       = Marty::Aws::ApigatewayApiStageView
    c.collapsible = true
    c.split       = true
    c.region      = :east
    c.width       = '20%'
  end

  component :aws_apigateway_api_usage_plan_view do |c|
    c.klass       = Marty::Aws::ApigatewayApiUsagePlanView
    c.collapsible = true
    c.split       = true
    c.region      = :east
    c.width       = '20%'
  end

  component :aws_apigateway_api_usage_plan_key_view do |c|
    c.klass       = Marty::Aws::ApigatewayApiUsagePlanKeyView
    c.collapsible = true
    c.split       = true
    c.region      = :east
    c.width       = '20%'
    c.collapsed   = true
  end

  component :aws_api_key_view do |c|
    c.klass       = Marty::Aws::ApiKeyView
    c.collapsible = true
    c.split       = true
    c.region      = :east
    c.width       = '20%'
  end
end

AwsApiView = Marty::Aws::ApiView
