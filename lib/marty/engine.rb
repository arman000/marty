module Marty
  class Engine < ::Rails::Engine
    isolate_namespace Marty

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
      'marty/dark_mode.css'
    ]

    config.action_cable.disable_request_forgery_protection = true
    # Can be overriden by config/cable.yml in Rails app
    ActionCable.server.config.cable ||= { 'adapter' => 'postgresql' }

    # TODO: Might want to move/refactor `env.yml` loading
    # in the future to its own initializer that will come before everything
    # else.
    initializer 'action_mailer', before: 'action_mailer.set_configs' do |app|
      app.config.action_mailer = ActionMailer::Base.configure do |amc|
        e = Rails.env
        is_production = e.production?
        app_name = ::Marty::RailsApp.application_name.downcase

        amc.raise_delivery_errors = !is_production
        amc.perform_caching = is_production
        amc.show_previews = !is_production
        amc.preview_path = Rails.root.join('spec/mailers/previews')
        amc.delivery_method = e.test? ? :test : :smtp
        amc.default_options = {
          from: "#{app_name}-#{e}@#{ENV['MAILER_SMTP_DOMAIN']}",
        }
        amc.smtp_settings = {
          address: ENV['MAILER_SMTP_ADDRESS'],
          port: ENV['MAILER_SMTP_PORT']&.to_i,
          domain: ENV['MAILER_SMTP_DOMAIN'],
          authentication: ENV['MAILER_AUTHENTICATION']&.to_sym,
          user_name: ENV['MAILER_SMTP_USERNAME'],
          password: ENV['MAILER_SMTP_PASSWORD']
        }.compact
        amc
      end
    end
  end
end
