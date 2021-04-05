module Marty
  class ApplicationMailer < ActionMailer::Base
    # This will make the default +from:+ field of the email be something like:
    #   Dummy (- Environment) <dummy-environment@domain.com>
    FROM_STRING = <<~FROM.squish
      #{Marty::RailsApp.application_name_with_env}
      <#{Marty::RailsApp.application_name.downcase}-#{Rails.env}@#{ENV['MAILER_SMTP_DOMAIN']}>
    FROM

    layout 'marty/mailer'
    default from: FROM_STRING

    # FIXME: Eventually move these next few lines to a +config/environments+
    # based setting.
    self.raise_delivery_errors = !Rails.env.production?
    self.show_previews = !Rails.env.production?
    self.perform_caching = Rails.env.production?
    self.preview_path = Rails.root.join('spec/mailers/previews')
    self.delivery_method = Rails.env.test? ? :test : :smtp

    self.smtp_settings = {
      address: ENV['MAILER_SMTP_ADDRESS'],
      port: ENV['MAILER_SMTP_PORT']&.to_i,
      domain: ENV['MAILER_SMTP_DOMAIN'],
      authentication: ENV['MAILER_AUTHENTICATION']&.to_sym || :smtp,
      user_name: ENV['MAILER_SMTP_USERNAME'],
      password: ENV['MAILER_SMTP_PASSWORD']
    }.compact
  end
end
