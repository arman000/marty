# frozen_string_literal: true

require 'tiny_tds'
require_relative 'sql_server/errors/connection_not_established_error'
require_relative 'sql_server/errors/database_configuration_error'

module Marty
  # This module is used as a sort of 'singleton' that implements connections
  # to SQL Server databases. It uses the `tiny_tds` gem under the hood, which
  # requires that FreeTDS be installed.
  #
  # This module gets its information about each database from `database.yml`
  # through `Rails.configuration.database_configuration`. `database.yml` shall
  # be defined with names of SQL Server databases starting with a prefix.
  #
  # @todo In the future, we should use connections pools here to allow for
  #   better performance and more flexibility.
  #
  # @example `database.yml`
  #   <%= Rails.env %>:
  #     adapter:  '<%= ENV['PSQL_ADAPTER'] %>'
  #     host:     '<%= ENV['DB_HOST'] %>'
  #     port:     '<%= ENV['DB_PORT'] %>'
  #     database: '<%= ENV['DB'] %>'
  #     encoding: '<%= ENV['ENCODING'] %>'
  #     username: '<%= ENV['DB_USER'] %>'
  #     password: '<%= ENV['DB_PASSWORD'] %>'
  #     reconnect: true
  #
  #   dbname_<%= Rails.env %>:
  #     sqlserver: true
  #     host:     '<%= ENV['DBNAME_DB_HOST'] %>'
  #     database: '<%= ENV['DBNAME_DB'] %>'
  #     username: '<%= ENV['DBNAME_DB_USER'] %>'
  #     password: '<%= ENV['DBNAME_DB_PASSWORD'] %>'
  #
  # @author Omri Gabay
  # @version 1.0
  module SqlServer
    # Sets the default TDSVER of FreeTDS based on an environment variable, or
    # a default variable of 7.3 (which is also the default that `tiny_tds`)
    # uses.
    TDSVER = Rails.application.config.marty.sql_server.tds_ver

    class << self
      # Takes the appropriate prefix for the database to connect to, and
      # returns a connection to said database. Can also take a block and yield
      # a connection object which lives for the duration of the block.
      #
      # @example Getting a simple connection
      #   conn = Marty::SqlServer.connection('dbname_') #=> <TinyTds::Client...>
      #   conn.execute(...)
      #   conn.close
      #
      # @example Using a temporary connection in a callback
      #   res = Marty::SqlServer.with_connection('dbname_') do |conn|
      #     conn.execute(...)
      #   end
      #   res.to_a
      #
      # @param prefix [String] The prefix of the DB from `database.yml`
      # @return [TinyTds::Client] if no block is given
      #
      # @yieldparam [TinyTds::Client] conn
      # @yieldreturn [Object]
      # @return [Object] if block is given; whatever the block returns
      def connection(prefix)
        conn = init_connection(prefix)
        apply_connection_params(conn)

        if block_given?
          res = yield(conn)
          conn.close if conn.active?

          res
        else
          conn
        end
      end
      alias with_connection connection

      # Used to run a one-off query against the database, and return the results
      # as an array. It returns the `Array` result of the query.
      # By default, it will close every connection after using it. This is to
      # avoid race conditions while we haven't implemented a connection pool.
      #
      # @todo Implement a `retry` system
      #
      # @param prefix [String] The prefix of the DB from `database.yml`
      # @param query [String] A correctly formatted SQL query string.
      #
      # @return [Array] An array of hashes containing the query's results
      # @raise [ArgumentError] if `prefix` isn't given
      # @raise [ArgumentError] if a query isn't given
      #   from the connection
      def exec_query(prefix, query)
        unless prefix
          raise ArgumentError,
                'Either a prefix or instantiated connection must given'
        end

        conn = connection(prefix)
        raise ArgumentError, 'Query must be given inside block' unless query

        conn.execute(query.squish).to_a
      rescue TinyTds::Error => e
        Rails.logger.error("[TinyTds] #{e}")
        Marty::Logger.error(
          'Marty::SqlServer',
          {
            prefix: prefix,
            exception: e.message,
            query: yield,
            db_error_number: e.db_error_number,
            os_error_number: e.os_error_number,
            severity: e.severity
          }
        )

        []
      ensure
        conn.close if conn.active?
      end

      # Applies connections params to the connection `conn`.
      #
      # @param conn [TinyTds::Client] The prefix of the DB from `database.yml`
      # @param params [Array<String>] The parameters to apply to a connection.
      # @return void
      def apply_connection_params(conn, params = default_connection_params)
        conn.execute(params.join("\n") + ';').do
      end

      private

      # Initializes a connection to a DB.
      #
      # @param prefix [String] The prefix of the DB from `database.yml`
      # @return [TinyTds::Client]
      #
      # @raise [Errors::DatabaseConfigurationError] if a configuration from
      #   `database.yml` is not found
      # @raise [Errors::ConnectionNotEstablishedError] if the connection is not
      #   active after initialization.
      def init_connection(prefix)
        config = Rails.configuration.database_configuration[prefix + Rails.env]
        raise Errors::DatabaseConfigurationError unless config

        conn = TinyTds::Client.new(**client_params(config))
        raise Errors::ConnectionNotEstablishedError unless conn.active?

        conn
      end
    end

    module_function

    # Default parameters Hash that is passed into every instance of
    # {TinyTds::Client.new}.
    #
    # @return [Hash<Symbol, String>]
    def default_client_params
      config = Rails.application.config.marty.sql_server

      {
        adapter: config.adapter,
        encoding: config.encoding,
        message_handler: message_handler,
        timeout: config.timeout,
        tds_version: TDSVER
      }.freeze
    end

    # The default connection parameters that will be applied to each
    # {TinyTds::Client} on creation. For more information on each parameter,
    # refer to the Microsoft SQL Server documentation.
    #
    # @param overrides [Hash] Override settings passed to the connection
    # @return [Array<String>]
    #
    # @note SQL Server Connection Settings Documentation:
    #   https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-padding-transact-sql?view=sql-server-ver15
    def default_connection_params(overrides = {})
      {
        # Enables ANSI_NULLS, ANSI_NULL_DFLT_ON, ANSI_PADDING, ANSI_WARNINGS,
        # CURSOR_CLOSE_ON_COMMIT, IMPLICIT_TRANSACTIONS,
        # QUOTED_IDENTIFIER (at parse time).
        ANSI_DEFAULTS: 'ON',
        # Causes SQL Server to follow the ISO rules regarding quotation mark
        # delimiting identifiers and literal strings. Identifiers delimited by
        # double quotation marks can be either Transact-SQL reserved keywords
        # or can contain characters not generally allowed by the Transact-SQL
        # syntax rules for identifiers.
        QUOTED_IDENTIFIER: 'ON',
        # Controls the behavior of the Transact-SQL COMMIT TRANSACTION statement.
        # The default value for this setting is OFF. This means that the server
        # will not close cursors when you commit a transaction.
        CURSOR_CLOSE_ON_COMMIT: 'OFF',
        # Sets the BEGIN TRANSACTION mode to OFF, for the connection.
        IMPLICIT_TRANSACTIONS: 'OFF',
        # Specifies the size of varchar(max), nvarchar(max), varbinary(max),
        # text, ntext, and image data returned by a SELECT statement.
        TEXTSIZE: 2_147_483_647,
        # Controls whether concatenation results are treated as null or empty
        # string values.
        CONCAT_NULL_YIELDS_NULL: 'ON',
      }.merge(overrides).map { |cp| get_set_statement(*cp) }.freeze
    end

    # Merges {default_client_params} with `configuration`. Used when
    # instantiating a new client.
    #
    # @param configuration [Hash]
    # @return [Hash]
    def client_params(configuration)
      default_client_params.merge(configuration.compact.symbolize_keys)
    end

    # A message handler used to display some of the internal messages sent out
    # by {TinyTds::Client}. It displays all messages sent to {Rails.logger}.
    #
    # @return [Proc]
    def message_handler
      lambda do |tds_msg|
        Rails.logger.info("[TinyTds] #{tds_msg.message}")
      end
    end
    private_class_method :message_handler

    # Used to generate the `SET` statements needed to apply connection settings
    # to a SQL Server connection.
    #
    # @param param [String, Symbol]
    # @param setting [String, Symbol]
    # @return [String]
    def get_set_statement(param, setting)
      "SET #{param.upcase} #{setting}"
    end
    private_class_method :get_set_statement
  end
end
