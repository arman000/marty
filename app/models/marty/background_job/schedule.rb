module Marty
  module BackgroundJob
    class Schedule < Marty::Base
      self.table_name = 'marty_background_job_schedules'

      # Copied and adjusted:
      # https://github.com/javan/whenever/blob/e4507e2ed2158c603f0c334a8b0a957711db343a/lib/whenever/cron.rb
      REGEX = %r{\A(((\*?[\d/,\-]*)\s){3,4}(\*?([\d/,\-])*\s)(\*?([\d/,\-])*))\z}i

      validates :job_class, :cron, :state, presence: true
      validates :cron, format: { with: REGEX }

      validate :job_class_validation
      validate :arguments_array_validation
      validate :job_class_uniqueness_validation

      has_one :delayed_job, class_name: '::Delayed::Job', dependent: :destroy

      ALL_STATES = %w[on off].freeze
      enum state: ALL_STATES.zip(ALL_STATES).to_h

      scope :by_arguments, lambda { |arguments|
        where('arguments = ?', arguments.to_json)
      }

      def job_class_validation
        job_class.constantize.respond_to?(:schedule)
      rescue NameError
        errors.add(:job_class, "doesn't exist")
        false
      end

      def arguments_array_validation
        return if arguments.is_a? Array

        errors.add(:arguments, 'must be an Array')
        false
      end

      def job_class_uniqueness_validation
        return unless self.class.by_arguments(arguments).
                        where.not(id: id).
                        where(job_class: job_class).any?

        errors.add(:arguments, 'are not unique')
        false
      end
    end
  end
end
