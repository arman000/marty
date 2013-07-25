module Marty
  class Engine < ::Rails::Engine
    isolate_namespace Marty

    # generators add rspec tests
    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
