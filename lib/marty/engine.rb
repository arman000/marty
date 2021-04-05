module Marty
  class Engine < ::Rails::Engine
    isolate_namespace Marty

    # Loads all keys from +env.yml+ to +ENV+.
    # @note This gets called before the application's `before_configuration`
    config.before_configuration do
      file_path = Rails.root.join('config/env.yml')
      next unless File.exist?(file_path)

      File.open(file_path) do |file|
        # Safely loads the env.yml file with alises enabled
        loaded_yaml = YAML.safe_load(file, aliases: true, filename: file.path)

        loaded_yaml[Rails.env].each do |key, value|
          # If ENV key already exists, don't overwrite it
          ENV[key.to_s] = value.to_s unless ENV[key.to_s]
        end
      end
    end

    # Load all configuration from +credentials.enc.yml+ to +ENV+.
    # Must have +master.key+ file in +config/+ for this to work properly.
    config.before_configuration do
      Rails.application.credentials[Rails.env.to_sym]&.each do |key, value|
        ENV[key.to_s] = value.to_s if ENV[key.to_s].blank?
      end
    end

    # eager load paths instead of autoload paths
    config.eager_load_paths += ['lib', 'other'].map do |dir|
      File.expand_path("../../#{dir}", __dir__)
    end

    # generators add rspec tests
    config.generators do |g|
      g.test_framework :rspec, view_specs: false
    end

    config.assets.precompile += [
      'marty/application.js',
      'marty/cable.js',
      'marty/application.css',
      'marty/dark_mode.css',
      'marty/diagnostic.css'
    ]

    config.action_cable.disable_request_forgery_protection = true

    # @note Can be overriden by config/cable.yml in Rails app
    ActionCable.server.config.cable ||= { 'adapter' => 'postgresql' }
  end
end
