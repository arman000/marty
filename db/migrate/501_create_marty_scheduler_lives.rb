class CreateMartySchedulerLives < ActiveRecord::Migration[4.2]
  def change
    create_table :marty_scheduler_lives, id: false do |t|

      # scheduler life table should never have more than one row
      t.boolean    :single_row_id,       null: false,
                                         primary_key: true,
                                         default: true

      t.integer    :pid,                 null: true
      t.inet       :ip,                  null: true
      t.integer    :processed,           null: false, default: 0
      t.datetime   :heartbeat,           null: true
      t.datetime   :created_at,          null: false
    end

    execute "ALTER TABLE marty_scheduler_lives "\
            "ADD CONSTRAINT scheduler_single_row CHECK (single_row_id);"
  end
end
