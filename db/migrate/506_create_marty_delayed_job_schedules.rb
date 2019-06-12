class CreateMartyDelayedJobSchedules < ActiveRecord::Migration[5.1]
  def change
    create_table :marty_background_job_schedules do |t|
      t.string :job_class, null: false
      t.string :cron, null: false
      t.string :state, null: false

      t.timestamps
    end

    add_index :marty_background_job_schedules, :job_class, unique: true
  end
end
