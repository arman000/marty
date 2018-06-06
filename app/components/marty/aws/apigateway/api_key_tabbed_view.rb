class Marty::Aws::Apigateway::ApiKeyTabbedView < Netzke::Base
  include Marty::Extras::Layout

  client_class do |c|
    c.extend = "Ext.tab.Panel"
  end

  def configure(c)
    super

    c.items  =
      [
        :aws_apigateway_api_key_view,
        :aws_apigateway_api_usage_plan_key_view,
      ]
  end

  component :aws_apigateway_api_key_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiKeyView
  end

  component :aws_apigateway_api_usage_plan_key_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiUsagePlanKeyView
  end
end

AwsApigatewayApiKeyTabbedView = Marty::Aws::Apigateway::ApiKeyTabbedView
