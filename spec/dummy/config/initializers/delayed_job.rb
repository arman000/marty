ENV['DELAYED_VER'] = `cd #{Rails.root.to_s}; git describe --tags --always`.strip

if Rails.env.test?
  # set a really small delay in test environment so that it doesn't
  # interfere as much with promise tests.
  Delayed::Worker.sleep_delay = 1
end
