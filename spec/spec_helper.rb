ENV["RAILS_ENV"] ||= "test"

require 'dummy/config/application'
require 'rspec/rails'

Dummy::Application.initialize!

ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include ScriptHelpers
  config.include DelayedJobHelpers
  config.include CleanDbHelpers

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.before(:suite) do
    load File.expand_path("../dummy/db/seeds.rb", __FILE__)
    #Mcfly.whodunnit = UserHelpers.create_test_user
    Marty::Engine.load_seed
    raise "Bad Posting count #{Marty::Posting.count}" unless
      Marty::Posting.count == 1
  end

  config.before(:each) do
    Mcfly.whodunnit = UserHelpers.system_user
  end

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
end
