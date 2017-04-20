class Marty::Log < Marty::Base

  def self.logfile
    @logfile ||= Rails.root.join('log', Rails.env + '.sql').to_s
  end

  establish_connection({
                         adapter:  "sqlite3",
                         database: logfile
                       })
  self.table_name = "log"
  self.primary_key = "id"

  def self.db_init
    db = SQLite3::Database.new(Marty::Log.logfile)
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS log (
      id INTEGER PRIMARY KEY,
      message_type TEXT,
      message TEXT,
      timestamp REAL,
      details BLOB )
      SQL
    db
  end

  def self.write_log(type, message, details)
    begin
      @db ||= db_init
      stmt = @db.prepare <<-SQL
          INSERT INTO log (message_type, message, timestamp, details)
            values (?, ?, ?, ?)
          SQL
      stmt.bind_param(1, type.to_s)
      stmt.bind_param(2, message)
      stmt.bind_param(3, Time.zone.now.to_f)
      stmt.bind_param(4, details.pretty_inspect)

      sent = false
      retries = 3
      delay = 0.1
      until sent
        begin
          stmt.execute
          sent = true
        rescue SQLite3::BusyException
          raise if retries == 0
          retries -= 1
          sleep delay
        end
      end

    rescue => e
      Marty::Util.logger.error("Marty::Logger failure: #{e.message}")
    ensure
      stmt.close if stmt rescue nil
    end
  end

  def self.cleanup(days_to_keep)
    raise "Must give numeric value. (Got '#{days_to_keep}')" unless
      (Float(days_to_keep) rescue false)
    @db ||= db_init
    cutoff = Time.zone.now.to_i - days_to_keep.to_i*60*60*24
    @db.execute <<-SQL
       delete from log where timestamp <= #{cutoff}
    SQL
  end
end
