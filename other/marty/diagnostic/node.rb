module Marty::Diagnostic::Node
  def self.my_ip
    begin
      Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.ip_address
    rescue => e
      e.message
    end
  end

  def self.get_postgres_connections
    conn = ActiveRecord::Base.connection.execute('SELECT datname,'\
                                                 'application_name,'\
                                                 'state,'\
                                                 'pid,'\
                                                 'client_addr '\
                                                 'FROM pg_stat_activity')
    conn.each_with_object({}) do |conn, h|
      h[conn['datname']] ||= []
      h[conn['datname']] << conn.except('datname')
    end
  end

  def self.get_target_connections target
    get_postgres_connections[Marty::Diagnostic::Database.db_name].select{|conn|
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
