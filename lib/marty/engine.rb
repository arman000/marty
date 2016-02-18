module Marty
  class Engine < ::Rails::Engine
    isolate_namespace Marty

    config.autoload_paths << File.expand_path("../../../lib", __FILE__)

    # generators add rspec tests
    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
