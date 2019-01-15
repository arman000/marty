source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'delayed_job_active_record'
gem 'daemons'
gem 'rails', '~> 5.1.4'
gem 'pg'
gem 'sqlite3'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'rspec-instafail', require: false
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'timecop'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'connection_pool'

  # gem 'mcfly', path: File.expand_path('../../mcfly', __FILE__)
  gem 'mcfly'
  gem 'netzke', '6.5.0.0'

  # gem 'delorean_lang', path: File.expand_path('../../delorean', __FILE__)

  # gem 'marty_rspec', path: File.expand_path('../../marty_rspec', __FILE__)
  gem 'marty_rspec'
end
