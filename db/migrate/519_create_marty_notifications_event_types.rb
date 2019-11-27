class CreateMartyNotificationsEventTypes < ActiveRecord::Migration[4.2]
  def up
    values = ::Marty::Notifications::EventType.values
    str_values = values.map {|v| ActiveRecord::Base.connection.quote v}.join ','

    execute <<-SQL
       CREATE TYPE marty_notifications_event_types AS ENUM (#{str_values});
    SQL
  end

  def down
    execute <<-SQL
       DROP TYPE marty_notifications_event_types;
    SQL
  end
end
