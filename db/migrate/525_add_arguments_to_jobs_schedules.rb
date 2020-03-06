class AddArgumentsToJobsSchedules < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_background_job_schedules, :arguments, :jsonb, default: [], null: false

    remove_index :marty_background_job_schedules, :job_class
    add_index :marty_background_job_schedules, [:job_class, :arguments], unique: true

    add_column :marty_background_job_logs, :arguments, :jsonb, default: [], null: false
  end
end
