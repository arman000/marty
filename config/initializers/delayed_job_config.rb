Delayed::Worker.default_queue_name = 'default'
Marty::Config['DELAYED_JOB_PARAMS'] ||= "-n #{Concurrent.physical_processor_count} --sleep-day 5"