class ScheduleJobToRemoveOldPromises < ActiveRecord::Migration[4.2]
  def up
    cron_every_hour = '0 * * * *'

    schedule = Marty::BackgroundJob::Schedule.new(
      job_class: 'Marty::RemoveOldPromisesJob',
      cron: cron_every_hour,
      state: 'on'
    )

    # Since we add `arguments` column to the model in later migrations,
    # we should skip it's validation here
    schedule.save!(validate: false)
  end

  def down
    Marty::BackgroundJob::Schedule.find_by(
      job_class: 'Marty::RemoveOldPromisesJob'
    )&.destroy
  end
end
