module Marty::Diagnostic::Node
  def self.my_ip
    begin
      Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address
    rescue => e
      e.message
    end
  end



  def self.get_target_connections target
    Marty::Diagnostic::Database.current_connections.select{|conn|
      conn['application_name'].include?(target)
    }.map{|conn|
      conn['client_addr'] == '127.0.0.1' ? my_ip :
        conn['client_addr'] || '127.0.0.1'
    }
  end

  def self.get_nodes
    nodes = get_target_connections('Passenger').uniq.compact
    nodes.empty? ? [my_ip] : nodes
  end
end
