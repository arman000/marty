module Marty::Diagnostic; class ServerTimeAndTz < Base
  def self.description
    <<~TEXT
      Returns the application server and database time.
    TEXT
  end

  diagnostic_fn(status_only: true) do
    begin
      D_FORMAT ||= '%Y-%m-%d'
      T_FORMAT ||= '%H:%M:%S'
      DT_FMT ||= "#{D_FORMAT} #{T_FORMAT}"

      app_time = Time.zone.now

      # to_s db_time result as Rails 6 returns time object instead of string
      db_time = Time.zone.parse(Marty::Diagnostic::Database.db_time.to_s)

      diff = (app_time - db_time).abs.round(1)

      # If the DB and App timezones are not the same and the DB
      # isn't storing timestamps with TZ (as is the rails default)
      # the McFly created_at datetimes will be interpreted incorrectly
      app_offset = app_time.utc_offset
      db_tz = Marty::Diagnostic::Database.db_timezone
      db_offset = Time.zone.now.in_time_zone(db_tz).utc_offset
      db_server = Marty::Diagnostic::Database.db_server_name

      (diff <= 1) && (app_offset == db_offset) ? 'In sync' : error(
        <<~ERRMSG
          App: #{app_time.strftime(DT_FMT)} #{app_time.time_zone}
          #{db_server}: #{db_time.strftime(DT_FMT)} #{db_tz}
        ERRMSG
      )
    rescue StandardError => e
      error(e.message)
    end
  end
end; end
