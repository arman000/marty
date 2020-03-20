class RescheduleAllJobs < ActiveRecord::Migration[5.1]
  def up
    Marty::BackgroundJob::Schedule.all.each do |job|

      puts job.attributes

      Marty::BackgroundJob::Schedule.where(
          job_class: job[:job_class]
        ).destroy_all

      if class_exists?(job[:job_class])
        new_job = Marty::BackgroundJob::Schedule.create!(job.attributes)
        "::#{job[:job_class]}".constantize.schedule(schedule_obj: new_job)
      end

    end
  end

  def down
    # do nothing?
  end

  def class_exists?(class_name)
    klass = Module.const_get(class_name)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end
end
