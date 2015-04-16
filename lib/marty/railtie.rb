module Marty
  class Railtie < Rails::Railtie
    config.marty = ActiveSupport::OrderedOptions.new
  end
end
