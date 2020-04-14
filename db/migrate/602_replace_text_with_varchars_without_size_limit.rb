class ReplaceTextWithVarcharsWithoutSizeLimit < ActiveRecord::Migration[5.1]
  def up
    drop_views
    execute <<SQL
      ALTER TABLE "delayed_jobs" ALTER COLUMN "locked_by" TYPE VARCHAR;
      ALTER TABLE "delayed_jobs" ALTER COLUMN "queue" TYPE VARCHAR;
      ALTER TABLE "delayed_jobs" ALTER COLUMN "cron" TYPE VARCHAR;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "app_name" TYPE VARCHAR;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "api_key" TYPE VARCHAR;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "script_name" TYPE VARCHAR;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "script" TYPE VARCHAR;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "node" TYPE VARCHAR;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "api_class" TYPE VARCHAR;
      ALTER TABLE "marty_background_job_logs" ALTER COLUMN "job_class" TYPE VARCHAR;
      ALTER TABLE "marty_background_job_logs" ALTER COLUMN "status" TYPE VARCHAR;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "job_class" TYPE VARCHAR;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "cron" TYPE VARCHAR;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "state" TYPE VARCHAR;
      ALTER TABLE "marty_configs" ALTER COLUMN "key" TYPE VARCHAR;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "name" TYPE VARCHAR;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "data_type" TYPE VARCHAR;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "constraint" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_booleans" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_int4ranges" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_integers" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_numranges" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_grid_index_strings" ALTER COLUMN "attr" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "name" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "db_model_name" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "synonym_fields" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "cleaner_function" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "validation_function" TYPE VARCHAR;
      ALTER TABLE "marty_import_types" ALTER COLUMN "preprocess_function" TYPE VARCHAR;
      ALTER TABLE "marty_logs" ALTER COLUMN "message_type" TYPE VARCHAR;
      ALTER TABLE "marty_logs" ALTER COLUMN "message" TYPE VARCHAR;
      ALTER TABLE "marty_notifications" ALTER COLUMN "state" TYPE VARCHAR;
      ALTER TABLE "marty_notifications_configs" ALTER COLUMN "delivery_type" TYPE VARCHAR;
      ALTER TABLE "marty_notifications_configs" ALTER COLUMN "state" TYPE VARCHAR;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "delivery_type" TYPE VARCHAR;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "state" TYPE VARCHAR;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "error_text" TYPE VARCHAR;
      ALTER TABLE "marty_postings" ALTER COLUMN "name" TYPE VARCHAR;
      ALTER TABLE "marty_postings" ALTER COLUMN "comment" TYPE VARCHAR;
      ALTER TABLE "marty_promises" ALTER COLUMN "title" TYPE VARCHAR;
      ALTER TABLE "marty_promises" ALTER COLUMN "cformat" TYPE VARCHAR;
      ALTER TABLE "marty_scripts" ALTER COLUMN "name" TYPE VARCHAR;
      ALTER TABLE "marty_tags" ALTER COLUMN "name" TYPE VARCHAR;
      ALTER TABLE "marty_tags" ALTER COLUMN "comment" TYPE VARCHAR;
      ALTER TABLE "marty_tokens" ALTER COLUMN "value" TYPE VARCHAR;
      ALTER TABLE "marty_users" ALTER COLUMN "login" TYPE VARCHAR;
      ALTER TABLE "marty_users" ALTER COLUMN "firstname" TYPE VARCHAR;
      ALTER TABLE "marty_users" ALTER COLUMN "lastname" TYPE VARCHAR;
SQL
    recreate_views
  end

  def down
    announce("No-op on ReplaceVarcharsWithText.down")
  end

  def drop_views
    execute <<SQL
      DROP VIEW IF EXISTS marty_vw_promises;
SQL
  end

  def recreate_views
    execute <<SQL
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
