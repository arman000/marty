class AddTimeoutToPromiseView < ActiveRecord::Migration[4.2]
  def up
    execute <<~SQL
       DROP VIEW IF EXISTS marty_vw_promises;
       CREATE OR REPLACE VIEW marty_vw_promises
       AS
       SELECT
       id,
       title,
       user_id,
       cformat,
       parent_id,
       job_id,
       status,
       start_dt,
       end_dt,
       priority,
       timeout
       FROM marty_promises;

       GRANT SELECT ON marty_vw_promises TO public;
    SQL
  end

  def down
    execute <<~SQL
       DROP VIEW IF EXISTS marty_vw_promises;
       CREATE OR REPLACE VIEW marty_vw_promises
       AS
       SELECT
       id,
       title,
       user_id,
       cformat,
       parent_id,
       job_id,
       status,
       start_dt,
       end_dt
       FROM marty_promises;

       GRANT SELECT ON marty_vw_promises TO public;
    SQL
  end
end
