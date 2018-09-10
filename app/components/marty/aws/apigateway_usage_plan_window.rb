class Marty::Aws::ApigatewayUsagePlanWindow < Netzke::Window::Base
  def configure(c)
    super

    c.title             = "Create AWS API Gateway Usage Plan"
    c.modal             = true
    c.items             = [:aws_apigateway_usage_plan_create_view]
    c.lazy_loading      = true
    c.width             = 800
    c.height            = 700
  end

  component :aws_apigateway_usage_plan_create_view do |c|
    c.klass = Marty::Aws::ApigatewayUsagePlanCreateView
  end
end
