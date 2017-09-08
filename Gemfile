source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'delayed_job_active_record'
gem 'daemons', '~> 1.1.9'
gem 'mime-types', '< 3.0', platforms: :ruby_19
gem 'rails', '~> 5.1.1'
gem 'pg', '~> 0.18.4'
gem 'sqlite3'

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'timecop'
  gem 'database_cleaner'
  gem 'rails-controller-testing'

  gem 'mcfly', git: 'https://github.com/thepry/mcfly.git', branch: 'rails-5-support'
  gem 'netzke', '6.5.0.0.rc2'

  gem 'marty_rspec'
end
