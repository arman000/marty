class AddScheduleIdToDelayedJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :delayed_jobs, :schedule_id, :integer
    add_index :delayed_jobs, :schedule_id

    reversible do |dir|
      dir.up { set_ids }
    end
  end

  def set_ids
    ::Marty::Jobs::Schedule.call
  end
end
