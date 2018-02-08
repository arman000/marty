class CreateMartyScheduledJobs < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_scheduled_jobs do |t|

      # break up cron syntax into separate fields
      t.string     :second,              null: false, default: '0'
      t.string     :minute,              null: false, default: '*'
      t.string     :hour,                null: false, default: '*'
      t.string     :day_of_the_month,    null: false, default: '*'
      t.string     :month_of_the_year,   null: false, default: '*'
      t.string     :day_of_the_week,     null: false, default: '*'
      t.string     :year,                null: false, default: '*'

      # used to peek at current status of scheduled job
      t.string     :status,              null: false, default: '---'

      # used to halt job from being processed
      t.boolean    :halt,                null: false, default: false

      # used to manage one off jobs and polling
      t.integer    :processed,           null: false, default: 0
      t.integer    :max_attempts,        null: true
      t.boolean    :got_result,          null: true

      # used to call delorean scripts
      t.json       :delorean_descriptor, null: false
      t.json       :params,              null: false, default: {}
      t.string     :description,         null: false

      # used to keep track of scheduled job results and behavior
      t.integer    :promise_id,          null: true
      t.integer    :user_id,             null: false

      # used for scheduling next job runs
      t.datetime   :last_completed_dt,   null: true
      t.datetime   :scheduled_run_dt,    null: true
      t.timestamps                       null: false
    end
    add_index(:marty_scheduled_jobs, :scheduled_run_dt)
  end
end
