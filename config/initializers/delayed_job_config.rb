Delayed::Worker.default_queue_name = 'default'
<<<<<<< HEAD
Marty::Config['DELAYED_JOB_PARAMS'] ||= "-n #{Concurrent.physical_processor_count} --sleep-day 5"
=======
Marty::Config['DELAYED_JOB_PARAMS'] ||= "-n #{Concurrent.physical_processor_count} --sleep-delay 5"
>>>>>>> 62d18f0f5d8646cad8617d1c3536e9217ce146b7
