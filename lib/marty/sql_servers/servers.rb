module Marty
  module SqlServers
    # Stores the configuration from +config/sql_servers.yml+.
    #
    # Is empty when +config/sql_servers.yml+ does not exist, or could not be
    # loaded.
    SERVERS = begin
                Rails.application.config_for(:sql_servers).with_indifferent_access
              rescue RuntimeError => e
                Rails.logger.warn('Could not load sql_servers.yml configuration file')
                {}
              end
  end
end
