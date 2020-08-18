class ScheduleDelayedJobWorkerReaperJob < ActiveRecord::Migration[5.1]
  def up

    # We set a maintenance window for when it is safe to restart delayed
    # jobs because the Reaper will timeout any jobs that are in process
    Marty::Config['DELAYED_JOBS_MAINTENANCE_WINDOW'] = {
      day: '*', range: ['01:00', '04:00']
    }

    every_20_mins_1am_to_4am = '*/20 1-4 * * *'

    Marty::BackgroundJob::Schedule.reset_column_information

    schedule = Marty::BackgroundJob::Schedule.new(
      job_class: 'Marty::DelayedJobWorkerReaperJob',
      cron: every_20_mins_1am_to_4am,
      state: 'off',
      arguments: [],
    )

    schedule.save!
  end

  def down
    Marty::BackgroundJob::Schedule.find_by(
      job_class: 'Marty::DelayedJobWorkerReaperJob'
    )&.destroy
  end
end
