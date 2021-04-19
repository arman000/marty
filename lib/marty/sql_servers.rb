# frozen_string_literal: true

# Don't require this file unless the SQL Server adapter can be loaded
begin
  require 'activerecord-sqlserver-adapter'
rescue LoadError => e
  Rails.logger.info(<<~INFO.squish)
    activerecord-sqlserver-adapter gem not found; skipping initialization...
  INFO
  return
end

require 'marty/sql_servers/servers'
require 'marty/sql_servers/adapter_patches'
require 'marty/sql_servers/client'

module Marty
  # {SqlServers} is responsible for providing & handling a unified interface
  # for querying Microsoft SQL Server databases, with the assumption that
  # they function like external services. This means we are not expecting
  # to use ActiveRecord or any sort of ORM-like functionality with them;
  # we simply care about querying.
  #
  # This component of {Marty} leverages the +activerecord-sqlserver-adapter+ gem,
  # and in doing so gives us certain niceties, like built in query logging
  # and debugging, along with NewRelic instrumentation.
  # We also make use of {::ActiveRecord::ConnectionAdapters::ConnectionHandler}
  # for wrapping our connections and giving us stable, multi-threaded
  # connection pools.
  #
  # Requiring this module will only load {SqlServers} into your runtime
  # if it detects that the SQL Server adapter gem has been installed.
  # Otherwise, it will silently fail.
  #
  # When {SqlServers} is loaded, it will also load {SqlServers::SERVERS}
  # which looks a file called +sql_servers.yml+ in your +config/+ folder.
  # Once it finds this file, it will generate a new {SqlServers::Client}
  # for each connection using the provided configuration.
  # The {SqlServers::Client} will hold a connection pool, without any connections
  # checked out by default. You can configure {SqlServers} to checkout
  # a connection by default for production using an initalizer like so:
  #
  #   # config/initializers/marty_sql_servers.rb
  #
  #   require 'marty/sql_servers'
  #
  #   Marty::SqlServers.generate_database_connections!(eager_start: Rails.env.production?)
  #
  #   # For convenience, alias SqlServers into the application namespace
  #   module Dummy
  #     SqlServers = Marty::SqlServers
  #   end
  #
  # Once the Client is created, it can be accessed from the {SqlServers}
  # module either as a constant, and also using Hash/dictionary notation
  #
  #   Marty::SqlServers::MySqlServerDb.exec_query('SELECT 1;')
  #   # OR
  #   Marty::SqlServers['my_sql_server_db'].exec_query('SELECT 1;')
  #   # OR
  #   Marty::SqlServers[:my_sql_server_db].exec_query('SELECT 1;')
  #
  # @example A sample +config/sql_servers.yml+ file
  #   ---
  #   .common: &common
  #     adapter: '<%= ENV['MSSQL_ADAPTER'] %>'
  #     encoding: '<%= ENV['ENCODING'] %>'
  #     reconnect: true
  #
  #   shared: # Rails 6.0+ only
  #     my_sql_server_db:
  #       <<: *common
  #       host: '<%= ENV['SQL_SERVER_DB_HOST'] %>'
  #       database: '<%= ENV['SQL_SERVER_DB'] %>'
  #       username: '<%= ENV['SQL_SERVER_DB_USER'] %>'
  #       password: '<%= ENV['SQL_SERVER_DB_PASSWORD'] %>'
  #
  # @see https://github.com/rails-sqlserver/activerecord-sqlserver-adapter
  module SqlServers
    @clients = ActiveSupport::HashWithIndifferentAccess.new

    # Generates all Database connections and stores them in +@client+
    #
    # @param eager_start [Boolean] Whether to checkout a DB connection from the pool
    #   automatically or not.
    # @return +true+ if the generation process was successful
    def self.generate_database_connections!(eager_start: false)
      SERVERS.each do |db_name, db_config|
        generate_database_connection!(db_name, db_config, eager_start: eager_start)
      end

      true
    end

    # Generates a single database connection.
    # @param db_name [String] The name of the db (e.g., +my_sql_server_db+)
    # @param db_config [Hash] The configuration object for the database.
    #   If one is not passed in, it looks for +db_name+ in {SERVERS}.
    # @param eager_start [Boolean] Whether to checkout a DB connection from the pool
    #   automatically or not.
    # @return +true+ if the generation process was successful
    def self.generate_database_connection!(db_name, db_config = nil, eager_start: false)
      db_config ||= SERVERS[db_name]
      db_class_name = db_name.to_s.camelcase
      db_class = const_set(db_class_name, Client.new(db_config))
      @clients[db_name] = db_class
      @clients[db_name].ensure_connection! if eager_start

      true
    end

    # Ensures a connection to each established database by attempting to check out a
    # connection from the pool for each one.
    #
    # @return [void]
    def self.ensure_all_connections!
      @clients.each_value(&:ensure_connection!)
    end

    # Retrieves the database from the +@clients+ hash
    #
    # @param db_name [String] The name of the db (e.g., +my_sql_server_db+)
    # @return [Marty::SqlServers::Client] The {Client} instance for DB +db_name+
    # @raise [NameError] if no such database client is found
    def self.[](db_name)
      found_client_instance = @clients[db_name]
      raise NameError, <<~ERROR.squish unless found_client_instance
        No Marty::SqlServers client instantiated with for the DB named "#{db_name}"
        in the current environment.
      ERROR

      found_client_instance
    end
  end
end
