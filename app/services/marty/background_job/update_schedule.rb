module Marty
  module BackgroundJob
    module UpdateSchedule
      def self.call(id:, job_class:)
        model = Marty::BackgroundJob::Schedule.find_by(id: id)

        if model.blank? || model.off?
          return remove_schedule(
            schedule_id: id,
            job_class: job_class
          )
        end

        return schedule(schedule_obj: model) if model.on?
      end

      def self.remove_schedule(schedule_id:, job_class:)
        klass = job_class.constantize
        return true unless klass.respond_to?(:remove_schedule)

        klass.remove_schedule(Delayed::Job.find_by(schedule_id: schedule_id))

        true
      rescue NameError
        false
      end

      def self.schedule(schedule_obj:)
        klass = schedule_obj.job_class.constantize

        return false unless klass.respond_to?(:schedule)

        klass.schedule(schedule_obj: schedule_obj)

        true
      rescue NameError
        false
      end
    end
  end
end
