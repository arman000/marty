module Marty
  class Railtie < Rails::Railtie
    config.marty = ActiveSupport::OrderedOptions.new
    config.marty.default_posting_type = 'BASE'
    config.marty.extjs_theme = 'classic'
  end
end
