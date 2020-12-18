if File.exist?('config/sql_servers.yml')
  require 'marty/sql_servers'

  Marty::SqlServers.generate_database_connections!(eager_start: Rails.env.production?)
end
