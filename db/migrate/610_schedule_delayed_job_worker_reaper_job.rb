class ScheduleDelayedJobWorkerReaperJob < ActiveRecord::Migration[5.1]
  def up
    every_eight_hours = '0 */8 * * *'

    Marty::BackgroundJob::Schedule.reset_column_information

    schedule = Marty::BackgroundJob::Schedule.new(
      job_class: 'Marty::DelayedJobWorkerReaperJob',
      cron: every_eight_hours,
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
