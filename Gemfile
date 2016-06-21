source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'responders'
gem 'delayed_job_active_record'
gem 'daemons', '~> 1.1.9'
gem 'mime-types', '< 3.0', platforms: :ruby_19
gem 'rails', '~> 4.2.1'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~>3.0'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'database_cleaner'

  gem 'netzke-core'
  gem 'netzke-basepack'

  gem 'marty_rspec'
end
