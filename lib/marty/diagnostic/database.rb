module Marty::Diagnostic::Database
  SIZES_SQL = <<~SQL.squish
    SELECT
      relname,
      pg_size_pretty(table_size)
    FROM (
      SELECT
        pg_catalog.pg_namespace.nspname AS schema_name,
        relname,
        pg_relation_size(pg_catalog.pg_class.oid) AS table_size
      FROM
        pg_catalog.pg_class
        JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid) t
    WHERE
      schema_name NOT LIKE 'pg_%'
    ORDER BY
      table_size DESC;
  SQL

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

  def self.db_timezone
    ActiveRecord::Base.connection.execute('SHOW TimeZone;')[0]['TimeZone']
  end

  def self.db_version
    ActiveRecord::Base.connection.execute('SELECT VERSION();')[0]['version']
  end

  def self.db_schema
    current = ActiveRecord::Migrator.current_version
    raise "Migration is needed.\nCurrent Version: #{current}" if
        ::Marty::RailsApp.needs_migration?

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

  def self.sizes
    ActiveRecord::Base.connection.exec_query(SIZES_SQL).rows
  end
end
