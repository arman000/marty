class CreateMartyScheduledJobsTrigger < ActiveRecord::Migration[4.2]
  def change
    connection.execute <<-SQL
    CREATE OR REPLACE FUNCTION notify_marty_scheduled_jobs()
      RETURNS trigger AS $$
    DECLARE
    BEGIN
     IF TG_OP = 'DELETE' THEN
       PERFORM pg_notify(
         CAST('marty_scheduled_jobs' AS text), ' ');
         RETURN OLD;
     ELSE
       PERFORM pg_notify(
         CAST('marty_scheduled_jobs' AS text), ' ');
         RETURN NEW;
     END IF;
    END;
    $$ LANGUAGE plpgsql;
    CREATE TRIGGER notify_marty_scheduled_job
    AFTER INSERT OR UPDATE OR DELETE ON marty_scheduled_jobs
    FOR EACH ROW
    EXECUTE PROCEDURE notify_marty_scheduled_jobs();
    SQL
  end
end
