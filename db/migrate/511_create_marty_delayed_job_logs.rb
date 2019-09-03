class CreateMartyDelayedJobLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :marty_background_job_logs do |t|
      t.string :job_class, null: false
      t.string :status, null: false
      t.jsonb :error

      t.timestamps
    end

    add_index :marty_background_job_logs, :job_class
  end
end
