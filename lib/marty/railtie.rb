module Marty
  class Railtie < Rails::Railtie
    config.marty = Marty::ApplicationConfig.new
  end
end
