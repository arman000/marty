class ScheduleJobToRemoveOldPromises < ActiveRecord::Migration[4.2]
  def up
    cron_every_hour = '0 * * * *'

    Marty::BackgroundJob::Schedule.create!(
      job_class: 'Marty::RemoveOldPromisesJob',
      cron: cron_every_hour,
      state: 'on'
    )

    ::Marty::RemoveOldPromisesJob.schedule
  end

  def down
    Marty::BackgroundJob::Schedule.find_by(
      job_class: 'Marty::RemoveOldPromisesJob'
    )&.destroy
  end
end
