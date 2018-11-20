module Marty::Diagnostic; class DelayedJobWorkers < Base
  diagnostic_fn do
    my_ip = Node.my_ip
    workers = Database.current_connections.map do |c|
      ip   = c['client_addr'] || '127.0.0.1'
      name = c['application_name']
      name if name.include?('delayed') && (ip == my_ip || ip == '127.0.0.1')
    end.compact.uniq.count
    {'Delayed Workers / Node' => workers.zero? ? error(workers) : workers}
  end
end
end
