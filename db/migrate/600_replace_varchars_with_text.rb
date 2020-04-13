class ReplaceVarcharsWithText < ActiveRecord::Migration[5.1]
  def up
    drop_views
    execute('
      ALTER TABLE "delayed_jobs" ALTER COLUMN "locked_by" TYPE TEXT;
      ALTER TABLE "delayed_jobs" ALTER COLUMN "queue" TYPE TEXT;
      ALTER TABLE "delayed_jobs" ALTER COLUMN "cron" TYPE TEXT;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "app_name" TYPE TEXT;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "api_key" TYPE TEXT;
      ALTER TABLE "marty_api_auths" ALTER COLUMN "script_name" TYPE TEXT;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "script" TYPE TEXT;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "node" TYPE TEXT;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_api_configs" ALTER COLUMN "api_class" TYPE TEXT;
      ALTER TABLE "marty_background_job_logs" ALTER COLUMN "job_class" TYPE TEXT;
      ALTER TABLE "marty_background_job_logs" ALTER COLUMN "status" TYPE TEXT;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "job_class" TYPE TEXT;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "cron" TYPE TEXT;
      ALTER TABLE "marty_background_job_schedules" ALTER COLUMN "state" TYPE TEXT;
      ALTER TABLE "marty_configs" ALTER COLUMN "key" TYPE TEXT;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "name" TYPE TEXT;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "data_type" TYPE TEXT;
      ALTER TABLE "marty_data_grids" ALTER COLUMN "constraint" TYPE TEXT;
      ALTER TABLE "marty_grid_index_booleans" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_grid_index_int4ranges" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_grid_index_integers" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_grid_index_numranges" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_grid_index_strings" ALTER COLUMN "attr" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "name" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "db_model_name" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "synonym_fields" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "cleaner_function" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "validation_function" TYPE TEXT;
      ALTER TABLE "marty_import_types" ALTER COLUMN "preprocess_function" TYPE TEXT;
      ALTER TABLE "marty_logs" ALTER COLUMN "message_type" TYPE TEXT;
      ALTER TABLE "marty_logs" ALTER COLUMN "message" TYPE TEXT;
      ALTER TABLE "marty_notifications" ALTER COLUMN "state" TYPE TEXT;
      ALTER TABLE "marty_notifications_configs" ALTER COLUMN "delivery_type" TYPE TEXT;
      ALTER TABLE "marty_notifications_configs" ALTER COLUMN "state" TYPE TEXT;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "delivery_type" TYPE TEXT;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "state" TYPE TEXT;
      ALTER TABLE "marty_notifications_deliveries" ALTER COLUMN "error_text" TYPE TEXT;
      ALTER TABLE "marty_postings" ALTER COLUMN "name" TYPE TEXT;
      ALTER TABLE "marty_postings" ALTER COLUMN "comment" TYPE TEXT;
      ALTER TABLE "marty_promises" ALTER COLUMN "title" TYPE TEXT;
      ALTER TABLE "marty_promises" ALTER COLUMN "cformat" TYPE TEXT;
      ALTER TABLE "marty_scripts" ALTER COLUMN "name" TYPE TEXT;
      ALTER TABLE "marty_tags" ALTER COLUMN "name" TYPE TEXT;
      ALTER TABLE "marty_tags" ALTER COLUMN "comment" TYPE TEXT;
      ALTER TABLE "marty_tokens" ALTER COLUMN "value" TYPE TEXT;
      ALTER TABLE "marty_users" ALTER COLUMN "login" TYPE TEXT;
      ALTER TABLE "marty_users" ALTER COLUMN "firstname" TYPE TEXT;
      ALTER TABLE "marty_users" ALTER COLUMN "lastname" TYPE TEXT;
    ')
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
