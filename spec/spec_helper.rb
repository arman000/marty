ENV["RAILS_ENV"] ||= "test"

require 'dummy/config/application'
require 'rspec/rails'
require 'database_cleaner'
require 'marty_rspec'

Capybara.register_driver :selenium do |app|
  capybara_cfg = TestingConfig.get_config("capybara_")
  if capybara_cfg && capybara_cfg['firefox_path']
    Selenium::WebDriver::Firefox::Binary.path = capybara_cfg['firefox_path']
  end
  client = Selenium::WebDriver::Remote::Http::Default.new
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile['general.useragent.override'] = "selenium"
  profile['browser.helperApps.neverAsk.openFile'] =
    'application/vnd.ms-excel, text/csv'
  profile['browser.helperApps.neverAsk.saveToDisk'] =
    'application/vnd.ms-excel, text/csv'

  profile["browser.download.manager.showWhenStarting"] = false
  profile["browser.download.folderList"] = 2
  profile["browser.download.dir"] = Marty::DownloadHelper::PATH.to_s

  profile.load_no_focus_lib = true

  if capybara_cfg && capybara_cfg['include_firebug']
    client.timeout = 600 # <= Page Load Timeout value in seconds
    profile.add_extension Rails.root.join(capybara_cfg['firebug_path'])
    profile["extensions.firebug.currentVersion"] = "3.0"
    profile["extensions.firebug.allPagesActivation"] = "on"
    profile["extensions.firebug.showFirstRunPage"] = false;
    ['console', 'net', 'script', 'cookies'].each do |feature|
      profile["extensions.firebug.#{feature}.enableSites"] = true
    end
    profile["extensions.firebug.framePosition"] = "detached"
    profile["extensions.firebug.showJSErrors"] = true
    profile["extensions.firebug.showXMLHttpRequests"] =true
    profile["extensions.firebug.showNetworkErrors"] = true
    profile["extensions.firebug.showStackTrace"] = true
    profile["extensions.firebug.defaultPanelName"] = "console"
  end

  Capybara::Selenium::Driver.new(app, :profile => profile, :http_client => client)
end

Dummy::Application.initialize!

ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

Dir[Rails.root.join("../support/**/*.rb")].each { |f| require f }

class ActiveRecord::Base
  mattr_accessor :shared_connection

  def self.clear_connection
    @@shared_connection = nil
  end

  clear_connection

  def self.connection
    @@shared_connection || retrieve_connection
  end

  def self.reset_shared_connection
    @@shared_connection = retrieve_connection
  end
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

RSpec.configure do |config|
  config.include DelayedJobHelpers
  config.include CleanDbHelpers
  config.include SpecSetup
  config.include Marty::IntegrationHelpers
  config.include MartyRSpec::Util
  config.include MartyRSpec::NetzkeGrid
  config.include Marty::DownloadHelper, :download

  Capybara.default_max_wait_time = 3

  # TODO: Continue to remove should syntax from specs - remove this line to see
  # errors
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }

  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.example_status_persistence_file_path = '.rspec-results'

  screenshot_root = "#{Rails.root.join("tmp")}/screenshots/"

  config.before(:suite) do
    `rm #{screenshot_root}*` if ENV["SCREENSHOT"]
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
  end

  config.before(:each) do
    Mcfly.whodunnit = UserHelpers.system_user
  end

  config.after(:each, :js => true) do |example|
    # save a screenshot on js failures for CI server testing
    if ENV["SCREENSHOT"] && example.exception
      meta = example.metadata
      filename = File.basename(meta[:file_path])
      line_number = meta[:line_number]
      screenshot_name = "screenshot-#{filename}-#{line_number}.png"
      page.save_screenshot("#{screenshot_root}#{screenshot_name}")
     end
  end

  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true
end
