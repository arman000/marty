require 'marty/sql_servers'

Marty::SqlServers.generate_database_connections!(eager_start: Rails.env.production?)

module Dummy
  SqlServers = Marty::SqlServers
end
