source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'delayed_job_active_record'
gem 'daemons', '~> 1.1.9'
gem 'mime-types', '< 3.0', platforms: :ruby_19
gem 'rails', '~> 4.2.1'
gem 'pg', '~> 0.18.4'
gem 'sqlite3'
# for signing of aws ec2 requests
gem 'aws-sigv4', '~> 1.0', '>= 1.0.2'


group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~>3.0'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'database_cleaner'

  gem 'netzke-core'
  gem 'netzke-basepack'
  gem 'netzke-testing'
  gem 'rspec-instafail', require: false

  gem 'marty_rspec'

  # gem 'delorean_lang', path: File.expand_path('../../delorean', __FILE__)
end
