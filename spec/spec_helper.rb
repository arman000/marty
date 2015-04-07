ENV["RAILS_ENV"] ||= "test"

require 'dummy/config/application'
require 'rspec/rails'

Dummy::Application.initialize!

ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.include DbSeedHelpers
  config.include UserHelpers
  config.include ScriptHelpers
  config.include DelayedJobHelpers
  config.include CleanDbHelpers
end
