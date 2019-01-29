class Marty::Log < Marty::Base
  # establish_connection creates a connection using the connection pool
  # based on the current AR connection (i.e. duplicates AR connection)
  establish_connection

  def self.write_log(type, message, details)
    begin
      create!(message_type: type,
              message: message,
              details: details,
              timestamp: Time.zone.now)
    rescue => e
      Marty::Util.logger.error("Marty::Logger failure: #{e.message}")
    end
    true
  end

  def self.cleanup(days_to_keep)
    raise "Must give numeric value. (Got '#{days_to_keep}')" unless
      (Float(days_to_keep) rescue false)

    where("timestamp <= ?", Time.zone.now - days_to_keep.to_i.days).delete_all
  end
end
