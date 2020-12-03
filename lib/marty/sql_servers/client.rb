module Marty
  module SqlServers
    # {Client} provides the interface for all actual interactions with the
    # database from code.
    class Client
      ConnectionHandler = ::ActiveRecord::ConnectionAdapters::ConnectionHandler
      include ActiveSupport::Callbacks

      class << self
        private

        # Generates a query method that calls the underlying method under the
        # hood. The call is also wrapped in custom +ActiveSupport+
        # instrumentation.
        #
        # @param exec_method [Symbol] the name of the method to be generated.
        # @return [Symbol] the name of the defined method
        #
        # @!macro [attach] generate_query_method
        #   @param sql [String] Raw SQL queries to send to the DB
        #   @!method $1(sql)
        def generate_query_method(exec_method)
          define_method(exec_method) do |sql|
            run_callbacks :instrumentation do
              instrument_query(exec_method, sql.squish)
            end
          end
        end
      end

      # @return [ActiveRecord::ConnectionAdapters::ConnectionHandler]
      #   the {ConnectionHandler} instance used internally
      attr_reader :handler

      # @return [ActiveRecord::ConnectionAdapters::ConnectionPool]
      #   the {ActiveRecord::ConnectionAdapters::ConnectionPool} instance used
      #   by {#handler}
      attr_reader :pool

      # @return [ActiveRecord::ConnectionAdapters::ConnectionSpecification]
      #   the connection specification for this specific database. It is
      #   generated from +db_config+.
      attr_reader :spec

      # @param db_config [Hash] the DB configuration object
      def initialize(db_config)
        @handler = ConnectionHandler.new
        @pool = @handler.establish_connection(db_config)
        @spec = @pool.spec
        @instrumenter = ActiveSupport::Notifications.instrumenter
      end

      # @!group Query methods

      # @return [Integer] the number of records/rows returned by the query
      generate_query_method :execute

      # @return [ActiveRecord::Result] a +ActiveRecord::Result+ object
      #   with the specific rows returned, columns, and column types.
      generate_query_method :exec_query

      # Handles running an +EXEC+ query on stored procedures in the database.
      # Can be provided with either positional or named arguments.
      #
      # @param proc_name [Symbol, String] The name of the stored procedure.
      # @param variables [Hash, Array] The variables to be passed to the stored
      #   procedure. Hash for positional, Array for named.
      #
      # @return [Array] Returns each individual row returned from the stored
      #   procedure's result.
      # @raise [ArgumentError] if +variables+ is not an +Array+ or +Hash+
      #
      # @todo Add ability to handle blocks like the original method
      def execute_procedure(proc_name, variables: {})
        raise ArgumentError, 'Variables must be of type Array or Hash' unless
              variables.is_a?(Hash) || variables.is_a?(Array)

        # Prepare the variables; either named or positional
        #
        # If hash: Needs to be wrapped in an array because of how the
        # original method expects it.
        prepared_vars = variables.is_a?(Hash) ? [variables] : variables

        sql = "EXEC #{proc_name}"
        run_callbacks :instrumentation do
          instrument_query(:execute_procedure, sql, vars: prepared_vars) do
            @pool.connection.execute_procedure(proc_name, *prepared_vars)
          end
        end
      end
      alias exec_procedure execute_procedure

      # @!endgroup

      # Ensures that a connection to the database is present by checking out
      # a connection from {#pool}.
      #
      # @raise [ActiveRecord::ConnectionNotEstablished] if no connection
      #   was checked out.
      # @return [void]
      def ensure_connection!
        @pool.connection
        raise ActiveRecord::ConnectionNotEstablished unless @pool.connected?
      end

      private

      define_callbacks :instrumentation
      set_callback :instrumentation, :before, :ensure_connection!

      # @return [void]
      def instrument_query(method_name, sql, vars: {})
        event_name = 'sql.sqlserver'
        request_data = {
          sql: sql,
          method_name: method_name,
          variables: if vars.empty?
                       nil
                     elsif vars.is_a?(Hash)
                       vars.compact
                     else
                      vars
                     end
        }.compact
        result = {}

        listeners_state = @instrumenter.start(event_name, request_data)
        begin
          result = if block_given?
                     yield
                   else
                     @pool.connection.send(method_name, sql)
                   end
        rescue StandardError => e
          result[:exception] = [e.class.name, e.message]
          result[:exception_object] = e
          raise e
        ensure
          @instrumenter.finish_with_state(
            listeners_state,
            event_name,
            {
              database: @spec.to_hash.slice(:host, :database),
              request: request_data,
              result: result
            }.compact
          )
        end
      end
    end
  end
end
