module Marty
  class Engine < ::Rails::Engine
    isolate_namespace Marty

    # eager load paths instead of autoload paths
    config.eager_load_paths += ['lib', 'other'].map do |dir|
      File.expand_path("../../../#{dir}", __FILE__)
    end

    # generators add rspec tests
    config.generators do |g|
      g.test_framework :rspec, view_specs: false
    end

    config.assets.precompile += [
      'marty/application.js',
      'marty/application.css',
      'marty/dark_mode.css'
    ]
  end
end
