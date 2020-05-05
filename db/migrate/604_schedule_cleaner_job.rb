class ScheduleCleanerJob < ActiveRecord::Migration[5.1]
  def up
    noon_on_saturdays_cron = '0 12 * * 6'

    Marty::BackgroundJob::Schedule.reset_column_information

    schedule = Marty::BackgroundJob::Schedule.new(
      job_class: 'Marty::CleanerJob',
      cron: noon_on_saturdays_cron,
      state: 'off',
      arguments: [],
    )

    schedule.save!
  end

  def down
    Marty::BackgroundJob::Schedule.find_by(
      job_class: 'Marty::CleanerJob'
    )&.destroy
  end
end
