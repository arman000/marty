class AddRunByToPromises < ActiveRecord::Migration[5.1]
  def change
    add_column :marty_promises, :run_by, :string, limit: nil

    reversible do |dir|
      dir.down  do
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

      dir.up do
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
          timeout,
          run_by
          FROM marty_promises;

          GRANT SELECT ON marty_vw_promises TO public;
        SQL
      end
    end
  end
end
