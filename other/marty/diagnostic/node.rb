module Marty::Diagnostic::Node
  def self.my_ip
      Socket.ip_address_list.detect(&:ipv4_private?).ip_address
  rescue StandardError => e
      e.message
  end

  def self.get_target_connections target
    Marty::Diagnostic::Database.current_connections.select do |conn|
      conn['application_name'].include?(target)
    end.map do |conn|
      conn['client_addr'] == '127.0.0.1' ? my_ip :
        conn['client_addr'] || '127.0.0.1'
    end
  end

  def self.get_nodes
    nodes = get_target_connections('Passenger').uniq.compact
    nodes.empty? ? [my_ip] : nodes
  end
end
