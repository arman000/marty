ENV['RAILS_ENV'] ||= 'test'
ENV['TZ'] ||= 'America/Los_Angeles'

require 'dummy/config/application'
require 'rspec/rails'
require 'database_cleaner'

support = Pathname.new(__FILE__).parent.to_s + '/support'
require "#{support}/suite"
require "#{support}/shared_connection"

Dummy::Application.initialize! unless Dummy::Application.initialized?

ActiveRecord::Migration.migrate File.expand_path('../../db/migrate/', __FILE__)
ActiveRecord::Migration.migrate File.expand_path('../dummy/db/migrate/', __FILE__)

require 'rspec/retry'

RSpec.configure do |config|
  config.include Marty::RSpec::Suite
  config.include Marty::RSpec::SharedConnection
  config.include Marty::RSpec::SharedConnectionDbHelpers

  # RspecMarty::SharedConnection.classes_to_exclude_shared = ['Marty::Log']
  Capybara.default_max_wait_time = 3

  # TODO: Continue to remove should syntax from specs - remove this line to see
  # errors
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }

  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.example_status_persistence_file_path = '.rspec-results'

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
  end

  config.before(:each) do
    marty_whodunnit
  end

  config.after(:each, js: true) do |example|
    # save a screenshot on js failures for CI server testing
    if example.exception
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      screenshot_path = "#{Rails.root.join("tmp")}/#{screenshot_name}"
      page.save_screenshot(screenshot_path)
     end
  end

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  Netzke::Testing.rspec_init(config)

  config.verbose_retry = true
  config.display_try_failure_messages = true

  if ENV['RSPEC_AUTO_RETRY_JS'] == 'true'
    config.around :each, :js do |ex|
      ex.run_with_retry retry: 3
    end

    config.retry_callback = proc do |ex|
      # run some additional clean up task - can be filtered by example metadata
      Capybara.reset! if ex.metadata[:js]
    end
  end
end
