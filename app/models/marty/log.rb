class Marty::Log < Marty::Base
  # establish_connection creates a connection using the connection pool
  # based on the current AR connection (i.e. duplicates AR connection)
  establish_connection

  # create json object accessors from the fields in details if possible
  after_initialize :add_field_accessors
  after_save       :add_field_accessors

  def add_store_accessor field
    singleton_class.class_eval {store_accessor :details, field}
  end

  def add_field_accessors
    num_fields = details.try(:keys).try(:count) || 0
    details.keys.each {|field| add_store_accessor field} if num_fields > 0
  end

  def self.write_log(type, message, details)
    begin
      create!(message_type: type,
              message: message,
              details: details,
              timestamp: Time.zone.now)
    rescue => e
      Marty::Util.logger.error("Marty::Logger failure: #{e.message}")
    end
  end

  def self.cleanup(days_to_keep)
    raise "Must give numeric value. (Got '#{days_to_keep}')" unless
      (Float(days_to_keep) rescue false)
    where("timestamp <= ?", Time.zone.now - days_to_keep.to_i.days).delete_all
  end
end
