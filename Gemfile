source 'http://rubygems.org'

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :default do
  gem 'daemons'
  gem 'delayed_job_active_record'
  gem 'pg'
  gem 'rails'
end

group :default, :cmit do
  gem 'delorean_lang'
  gem 'mcfly'
  # gem 'delorean_lang', path: File.expand_path('../../delorean', __FILE__)
  # gem 'mcfly', path: File.expand_path('../../mcfly', __FILE__)
end

group :development, :test do
  gem 'benchmark-ips'
  gem 'capybara'
  gem 'connection_pool'
  gem 'database_cleaner'
  gem 'fuubar', require: false
  gem 'netzke', '6.5.0.0'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'puma'
  gem 'rails-controller-testing'
  gem 'rspec-instafail', require: false
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'webdrivers'
end
