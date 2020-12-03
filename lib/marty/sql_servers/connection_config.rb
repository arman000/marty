# frozen_string_literal: true

module Marty
  module SqlServers
    # Setting and configuration management for {SqlServers::Client} DB
    # connections.
    module ConnectionConfig
      # The default connection settings that are applied to every SQL Server
      # connection.
      DEFAULT_SETTINGS = {
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
      }

      module_function

      # Returns an array of +SET+ statements that will be applied to each
      # SQL Server connection on creation. For more information on each parameter,
      # refer to the Microsoft SQL Server documentation.
      #
      # @see DEFAULT_SETTINGS the default settings
      #
      # @param overrides [Hash] Additional settings to override or add.
      # @param replace [Boolean] Whether to merge the overrides with
      #   the defaults or just use them by themselves.
      # @return [Array<String>]
      #
      # @note SQL Server Connection Settings Documentation:
      #   https://docs.microsoft.com/en-us/sql/t-sql/statements/set-ansi-padding-transact-sql?view=sql-server-ver15
      def get_settings(overrides: {}, replace: false)
        final_config = replace ? overrides : DEFAULT_SETTINGS.merge(overrides)
        final_config.map { |cp| get_set_statement(*cp) }.freeze
      end

      # Used to generate the +SET+ statements needed to apply connection settings
      # to a SQL Server connection.
      #
      # @param param [String, Symbol]
      # @param setting
      # @return [String]
      def get_set_statement(param, setting)
        "SET #{param.upcase} #{setting}"
      end
      private_class_method :get_set_statement
    end
  end
end
