class AddScheduleIdToDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :delayed_jobs, :schedule_id, :integer
    add_index :delayed_jobs, :schedule_id

    reversible do |dir|
      dir.up do
        set_ids
        reschedule_jobs
      end
    end
  end

  def set_ids
    ::Marty::Jobs::Schedule.call
  end

  def reschedule_jobs
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

  def class_exists?(class_name)
    klass = Module.const_get(class_name)
    return klass.is_a?(Class)
  rescue NameError
    return false
  end

end
