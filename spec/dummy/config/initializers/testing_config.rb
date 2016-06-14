module Dummy::TestingConfig
  TESTING_CONFIG_PATH = "#{Rails.root}/config/testing.yml"
  DEFAULT_HASH = { "capybara_test" => { "include_firebug" => false } } 

  if FileTest.exists? TESTING_CONFIG_PATH then
    @testing_config = YAML.load_file("#{Rails.root}/config/testing.yml")
  else
    @testing_config = DEFAULT_HASH
  end

  def self.get_config(pfx)
    @testing_config[pfx + Rails.env]
  end
end
