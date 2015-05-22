source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'responders'
gem 'delayed_job_active_record'
gem 'daemons', '~> 1.1.9'

group :development, :test do
  gem 'rails', '~> 4.2.1'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 2.99.0'
  gem 'capybara', '~> 1.1.4'
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'database_cleaner'
  gem 'netzke', github: 'netzke/netzke'
  gem 'netzke-core', github: 'netzke/netzke-core'
  gem 'netzke-basepack', github: 'netzke/netzke-basepack'
  gem 'netzke-testing', github: 'ratdaddy/netzke-testing'
end
