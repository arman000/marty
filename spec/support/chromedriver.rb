require 'selenium-webdriver'
require Pathname.new(__FILE__).parent.to_s + '/download_helper'

module Marty; module RSpec; module Chromedriver
  def self.register_chrome_driver driver= :chrome, opts={}
    Capybara.register_driver driver do |app|
      copts = {
        chromeOptions: opts.deep_merge(
          prefs: {'download.default_directory' =>
                  Marty::RSpec::DownloadHelper::PATH.to_s}),
        pageLoadStrategy: 'none',
      }
      caps = Selenium::WebDriver::Remote::Capabilities.chrome(copts)
      driver = Capybara::Selenium::Driver.new(app,
                                              browser: :chrome,
                                              desired_capabilities: caps)
      yield driver if block_given?
      driver
    end
  end

  register_chrome_driver

  headless_args =  %w[headless disable-gpu window-size=3840,2160]
  register_chrome_driver(:headless_chrome, args: headless_args) do |driver|

    # workaround to enable downloading with headless chrome
    bridge = driver.browser.send(:bridge)
    bridge.http.call(:post,
                     "/session/#{bridge.session_id}/chromium/send_command",
                     cmd: 'Page.setDownloadBehavior',
                     params: {
                       behavior: 'allow',
                       downloadPath: Marty::RSpec::DownloadHelper::PATH.to_s
                     })
  end

  Capybara.default_driver    = :chrome
  Capybara.javascript_driver = ENV['HEADLESS'] == 'true' ?
                                 :headless_chrome : :chrome
end end end
