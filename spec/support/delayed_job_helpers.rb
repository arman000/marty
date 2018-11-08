module Marty::RSpec::DelayedJobHelpers
  def start_delayed_job
    # start delayed job workers and wait a few seconds
    `RAILS_ENV=test spec/dummy/script/delayed_job -n 4 stop | cat`
    `RAILS_ENV=test spec/dummy/script/delayed_job -n 4 start | cat`
    sleep 5
  end

  def stop_delayed_job
    `RAILS_ENV=test spec/dummy/script/delayed_job -n 4 stop | cat`
  end
end
