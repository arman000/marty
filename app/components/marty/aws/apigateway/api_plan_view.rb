class Marty::Aws::Apigateway::ApiPlanView < Netzke::Base
  include Marty::Extras::Layout

  def configure(c)
    super

    c.layout = 'border'
    c.header = false
    c.items  =
      [
        {
          component:        :aws_apigateway_api_view,
          region: :north,
          border: false,
          height: '50%'
        },
        {
          component:        :aws_apigateway_api_usage_plan_view,
          region: :center,
          border: false,
          height: '50%'
        },
      ]
  end

  component :aws_apigateway_api_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiView
  end

  component :aws_apigateway_api_usage_plan_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiUsagePlanView
  end
end

AwsApigatewayApiPlanView = Marty::Aws::Apigateway::ApiPlanView
