# frozen_string_literal: true

# FIXME: This is included here as well because +eager_loading+ +lib/+ in Marty
# causes this to be loaded as well. We might want to figure out a better way
# to not load optional files.
#
# Don't require this file unless the SQL Server adapter can be loaded
begin
  require 'activerecord-sqlserver-adapter'
rescue LoadError => e
  Rails.logger.info(<<~INFO.squish)
    activerecord-sqlserver-adapter gem not found; skipping initialization...
  INFO
  return
end

module Marty
  module SqlServers
    # This module is responsible for several patches to the SQL Server adapter,
    # in order to modify its use better for our case. They are enabled by default
    # when requiring this file.
    module AdapterPatches
      Adapter = ::ActiveRecord::ConnectionAdapters::SQLServerAdapter

      # Enables the monkey patches by +prepend+ing {AdapterPatches} to the {Adapter}
      def self.enable!
        Adapter.prepend(Marty::SqlServers::AdapterPatches)
      end

      # Prepends +MS-SQL [#{db_name}]+ to all Transaction names which are used
      # by +Rails.logger+
      def do_execute(sql, _name = 'SQL')
        @sql_name ||= "MS-SQL [#{@connection_options[:database]}]"
        super(sql, @sql_name)
      end

      def raw_select(sql, _name = 'SQL', binds = [], options = {})
        @sql_name ||= "MS-SQL [#{@connection_options[:database]}]"
        super(sql, @sql_name, binds, options)
      end

      # This patch is the recommended way by SQLServerAdapter gem
      # maintainers for configuring the connection using +SET+ statements.
      #
      # @see https://github.com/rails-sqlserver/activerecord-sqlserver-adapter#configure-connection--app-name
      def configure_connection
        settings = Rails.application.config.marty.sqlserver_connection_settings
        settings.each do |config_stmt|
          raw_connection_do(config_stmt)
        end
      end
    end
  end
end

Marty::SqlServers::AdapterPatches.enable!
