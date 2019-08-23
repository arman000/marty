module Marty
  module BackgroundJob
    class Log < Marty::Base
      self.table_name = 'marty_background_job_logs'

      validates :job_class, :status, presence: true

      ALL_STATUSES = %w[success failure failure_ignore].freeze
      enum status: ALL_STATUSES.zip(ALL_STATUSES).to_h
    end
  end
end
