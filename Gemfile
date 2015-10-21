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
  gem 'rspec-rails', '~>3.0'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'database_cleaner'
  gem 'netzke-core'
  gem 'netzke-basepack'
  gem 'netzke-testing' #, path: File.expand_path('../../netzke-testing', __FILE__)
end
