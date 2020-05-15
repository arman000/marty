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
      'marty/cable.js',
      'marty/application.css',
      'marty/codemirror_override.css',
      'marty/dark_mode.css',
      'marty/ext_crisp_override.css',
      'marty/fonts.css.erb',
    ]

    config.action_cable.disable_request_forgery_protection = true
    # Can be overriden by config/cable.yml in Rails app
    ActionCable.server.config.cable ||= { 'adapter' => 'postgresql' }
  end
end
