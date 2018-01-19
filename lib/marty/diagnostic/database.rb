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
end
