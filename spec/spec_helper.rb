ENV["RAILS_ENV"] ||= "test"

require 'dummy/config/application'
require 'rspec/rails'
require 'database_cleaner'

Dummy::Application.initialize!

ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include DelayedJobHelpers
  config.include CleanDbHelpers

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)

    Marty::Engine.load_seed
    load File.expand_path("../dummy/db/seeds.rb", __FILE__)
  end

  config.before(:each) do
    Mcfly.whodunnit = UserHelpers.system_user
  end

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
end
