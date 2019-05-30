source 'http://rubygems.org'

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'daemons'
gem 'delayed_job_active_record'
gem 'pg'
gem 'rails', '~> 5.1.4'
gem 'sqlite3'

group :development, :test do
  gem 'capybara', '~> 2.18.0'
  gem 'connection_pool'
  gem 'database_cleaner'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rspec-instafail', require: false
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'selenium-webdriver'
  gem 'timecop'
  gem 'webdrivers'

  # gem 'mcfly', path: File.expand_path('../../mcfly', __FILE__)
  gem 'mcfly'
  gem 'netzke', '6.5.0.0'

  # gem 'delorean_lang', path: File.expand_path('../../delorean', __FILE__)

  # gem 'marty_rspec', path: File.expand_path('../../marty_rspec', __FILE__)
  gem 'marty_rspec'
end
