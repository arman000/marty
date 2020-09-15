class UseVarcharForJobIdInPromises < ActiveRecord::Migration[5.1]
  def change
    execute <<~SQL
      DROP VIEW IF EXISTS marty_vw_promises;
    SQL

    reversible do |dir|
      dir.down  do
        change_column :marty_promises, :job_id, :integer
      end

      dir.up  do
        change_column :marty_promises, :job_id, :string, limit: nil
      end
    end

    execute <<~SQL
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
end
