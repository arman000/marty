class Marty::Aws::Apigateway::ApiKeyMoveWindow < Netzke::Window::Base
  def configure(c)
    super

    c.title             = "Move AWS API Key to Usage Plan"
    c.modal             = true
    c.items             = [:aws_apigateway_api_key_move_view]
    c.lazy_loading      = true
    c.width             = 800
    c.height            = 700
  end

  component :aws_apigateway_api_key_move_view do |c|
    c.klass = Marty::Aws::Apigateway::ApiKeyMoveView
  end
end
