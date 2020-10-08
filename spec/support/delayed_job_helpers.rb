module Marty::RSpec::DelayedJobHelpers
  def start_delayed_job
    `RAILS_ENV=test #{Rails.root}/bin/delayed_job -n 8 stop | cat`
    `RAILS_ENV=test #{Rails.root}/bin/delayed_job -n 8 start | cat`
    sleep 5
  end

  def stop_delayed_job
    `RAILS_ENV=test #{Rails.root}/bin/delayed_job -n 8 stop | cat`
  end
end
