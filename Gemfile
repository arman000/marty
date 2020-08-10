source 'https://rubygems.org'

# Declare your gem's dependencies in marty.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :default do
  gem 'daemons'
  gem 'delayed_job_active_record'
  gem 'netzke'
  gem 'pg'
  gem 'rails'
  group :cmit do
    gem 'delorean_lang', git: 'https://gitlab.pnmac.com/cm_tech/delorean.git'
    gem 'mcfly', git: 'https://gitlab.pnmac.com/cm_tech/mcfly.git'
    # gem 'delorean_lang', path: File.expand_path('../delorean', __dir__)
    # gem 'mcfly', path: File.expand_path('../mcfly', __dir__)
  end
end

group :development, :test do
  group :cmit do
    gem 'cm_shared', git: 'https://gitlab.pnmac.com/cm_tech/cm_shared.git'
    # gem 'cm_shared', path: File.expand_path('../cm_shared', __dir__)
  end
  gem 'benchmark-ips'
  gem 'capybara'
  gem 'connection_pool'
  gem 'database_cleaner'
  gem 'fuubar', require: false
  gem 'pry'
  gem 'rails-controller-testing'
  gem 'rspec-instafail', require: false
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'rubocop', '0.89.0', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webdrivers'
end
