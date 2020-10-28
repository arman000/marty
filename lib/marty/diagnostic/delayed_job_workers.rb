module Marty::Diagnostic; class DelayedJobWorkers < Base
  DIAG_NAME ||= 'Delayed Workers / Node'
  DIAG_CONFIG_TARGET ||= 'DIAG_DELAYED_TARGET'

  def self.description
    <<~TEXT
      Reports the number of delayed job workers on each node.
    TEXT
  end

  diagnostic_fn do
    my_ip = Node.my_ip
    workers = Database.current_connections.map do |c|
      ip   = c['client_addr'] || '127.0.0.1'
      name = c['application_name']
      name if name.include?('delayed') && (ip == my_ip || ip == '127.0.0.1')
    end.compact.uniq.count

    target_count = Marty::Config[DIAG_CONFIG_TARGET]

    next { DIAG_NAME => workers.zero? ? error(workers) : workers } unless
      target_count

    next { DIAG_NAME => error("invalid type for #{DIAG_CONFIG_TARGET}") } unless
      target_count.is_a?(Integer)

    { DIAG_NAME => workers == target_count ? workers : error(workers) }
  end
end
end
