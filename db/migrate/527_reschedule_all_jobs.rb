class RescheduleAllJobs < ActiveRecord::Migration[5.2]
  def up
    Marty::BackgroundJob::Schedule.all.each do |job|
      Marty::BackgroundJob::Schedule.where(
          job_class: job[:job_class]
        ).destroy_all

      new_job = Marty::BackgroundJob::Schedule.create!(
          job_class: job[:job_class],
          cron: job[:cron],
          state: job[:state]
        )

      "::#{job[:job_class]}".constantize.schedule(schedule_obj: new_job)
  end

  def down
    announce("No-op on RescheduleAllJobs.down")
  end
end
