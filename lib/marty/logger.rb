class Marty::Logger
  include Delorean::Model

  def self.method_missing(m, *args, &block)
    return super unless
      [:debug, :info, :warn, :error, :fatal, :unknown].include?(m)

    Marty::Util.logger.send(m, args[0]) if Marty::Util.logger.respond_to?(m)
    log(m, *args)
  end

  def self.log(type, message, details = nil)
    Marty::Log.write_log(type, message, details)
  end

  def self.with_logging(error_message, error_data)
      yield
  rescue StandardError => e
      error(error_message,  "message" => e.message,
                             "data" => error_data)
      raise "#{error_message}: #{e.message}"
  end

  delorean_fn :dllog, sig: [2, 20] do |*args|
     info args[0], args[1..-1]
  end
end
