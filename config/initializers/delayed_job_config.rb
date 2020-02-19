require 'etc'

Delayed::Worker.default_queue_name = 'default'
Marty::Config['DELAYED_JOB_PARAMS'] ||= "-n #{Etc.nprocessors} --sleep-delay 5"
