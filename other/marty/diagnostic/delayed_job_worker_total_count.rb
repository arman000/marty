module Marty::Diagnostic; class DelayedJobWorkerTotalCount < Base
  diagnostic_fn(aggregatable: false) do
    count = Database.current_connections.map do |c|
      [c['application_name'], c['client_addr'] || '127.0.0.1'] if
        c['application_name'].include?('delayed')
    end.compact.uniq.count
    { 'Delayed Workers' => count.zero? ? error(count) : count }
  end
end
end
