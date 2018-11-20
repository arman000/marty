module Marty::Diagnostic::Database
  def self.db_name
    ActiveRecord::Base.connection_config[:database]
  end

  def self.db_server_name
    ActiveRecord::Base.connection_config[:host] || 'undefined'
  end

  def self.db_adapter_name
    ActiveRecord::Base.connection.adapter_name
  end

  def self.db_time
    ActiveRecord::Base.connection.execute('SELECT NOW();')[0]['now']
  end

  def self.db_version
    ActiveRecord::Base.connection.execute('SELECT VERSION();')[0]['version']
  end

  def self.db_schema
    current = ActiveRecord::Migrator.current_version
    raise "Migration is needed.\nCurrent Version: #{current}" if
      ActiveRecord::Migrator.needs_migration?
    current.to_s
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

  def self.current_connections
    get_postgres_connections[db_name]
  end
end
