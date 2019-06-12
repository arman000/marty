module Marty
  module BackgroundJob
    module UpdateSchedule
      def self.call(id:, job_class:)
        model = Marty::BackgroundJob::Schedule.find_by(id: id)

        return remove_schedule(job_class: job_class) unless model.present?
        return remove_schedule(job_class: job_class) if model.off?
        return schedule(job_class: job_class) if model.on?
      end

      def self.remove_schedule(job_class:)
        klass = job_class.constantize
        klass.remove_schedule if klass.respond_to?(:remove_schedule)

        true
      rescue NameError
        false
      end

      def self.schedule(job_class:)
        klass = job_class.constantize

        return false unless klass.respond_to?(:schedule)

        klass.schedule

        true
      rescue NameError
        false
      end
    end
  end
end
