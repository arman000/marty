module Marty
  module BackgroundJob
    class Schedule < Marty::Base
      self.table_name = 'marty_background_job_schedules'

      # Copied and adjusted:
      # https://github.com/javan/whenever/blob/e4507e2ed2158c603f0c334a8b0a957711db343a/lib/whenever/cron.rb
      REGEX = %r{\A(((\*?[\d/,\-]*)\s){3,4}(\*?([\d/,\-])*\s)(\*?([\d/,\-])*))\z}i

      validates :job_class, :cron, :state, presence: true
      validates :job_class, uniqueness: true
      validates :cron, format: { with: REGEX }

      validate :job_class_validation

      ALL_STATES = %w[on off].freeze
      enum state: ALL_STATES.zip(ALL_STATES).to_h

      def job_class_validation
        job_class.constantize.respond_to?(:schedule)
      rescue NameError
        errors.add(:job_class, "doesn't exist")
        false
      end
    end
  end
end
