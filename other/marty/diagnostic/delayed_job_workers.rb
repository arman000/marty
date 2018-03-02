module Marty::Diagnostic; class DelayedJobWorkers < Base
  diagnostic_fn do
    my_ip = Node.my_ip
    count = Node.get_target_connections('delayed').count{
      |ip|
      (ip == my_ip || ip == '127.0.0.1')
    }
    count.zero? ? error(count) : count
  end
end
end
