module Marty
  module Cleaner
    module CleanAll
      LOG_DAYS_KEY = 'log_days'
      MCFLY_DAYS_KEY = 'mcfly_days'
      TS_DAYS_KEY = 'timestamp_days'

      class << self
        def log(table_type, table_name)
          ::Marty::Logger.log(table_type, 'Start Clean', table_name)
          count = yield
          ::Marty::Logger.log(
            table_type,
            'End Clean',
            "#{table_name} (#{count} records deleted)"
          )
        end

        def call
          window_config = ::Marty::Cleaner::MaintenanceWindow.call
          log_days = window_config.fetch(LOG_DAYS_KEY, 60)
          mcfly_days = window_config.fetch(MCFLY_DAYS_KEY, 365 * 3)
          ts_days = window_config.fetch(TS_DAYS_KEY, 365 * 3)

          [
            [LOG_DAYS_KEY, log_days],
            [MCFLY_DAYS_KEY, mcfly_days],
            [TS_DAYS_KEY, ts_days]
          ].each do |key, value|
            raise "'#{key}' must be an integer" unless value.is_a?(Integer)
          end
          ::Marty::Cleaner::Logs.call(log_days)
          ::Marty::Cleaner::McflyModels.call(mcfly_days)
          ::Marty::Cleaner::TimestampModels.call(ts_days)
        end
      end
    end
  end
end
