source "http://rubygems.org"

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'delayed_job_active_record'
gem 'daemons', '~> 1.1.9'
gem 'rails', '~> 4.2.10'
gem 'pg'
gem 'sqlite3'
# for signing of aws ec2 requests
gem 'aws-sigv4', '~> 1.0', '>= 1.0.2'


group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails', '~>3.0'
  gem 'capybara'
  gem "selenium-webdriver", '~> 2.53.4'
  gem 'timecop'
  gem 'database_cleaner'

  gem 'netzke-core'
  gem 'netzke-basepack'
  gem 'netzke-testing'
  gem 'rspec-instafail', require: false

gem 'marty_rspec', path: File.expand_path('../../marty_rspec', __FILE__) 
#  gem 'marty_rspec'
end
