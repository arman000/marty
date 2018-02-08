module DelayedJobHelpers
  def start_delayed_job n = 4, sleep_time = 5
    # start delayed job workers and wait a few seconds
    `RAILS_ENV=test spec/dummy/script/delayed_job -n #{n} stop | cat`
    `RAILS_ENV=test spec/dummy/script/delayed_job -n #{n} start | cat`
    sleep sleep_time
  end

  def stop_delayed_job
    `RAILS_ENV=test spec/dummy/script/delayed_job stop | cat`
  end
end
