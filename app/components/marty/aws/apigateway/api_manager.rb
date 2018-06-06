class Marty::Aws::Apigateway::ApiManager < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super
    c.layout = 'border'
    c.header = false
    c.items  =
      [
        {
          component: :aws_apigateway_api_plan_view,
          region: :west,
          border: false,
          width: '50%',
        },
        {
          component: :aws_apigateway_api_key_tabbed_view,
          region: :center,
          width: '50%',
          border: false,
        }
      ]
  end

  component :aws_apigateway_api_plan_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiPlanView
  end

  component :aws_apigateway_api_key_tabbed_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiKeyTabbedView
  end
end

AwsApigatewayApiManager = Marty::Aws::Apigateway::ApiManager
