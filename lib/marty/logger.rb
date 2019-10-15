class Marty::Logger
  include Delorean::Model

  delorean_fn :dllog, sig: [2, 20] do |*args|
    info args[0], args[1..-1]
  end

  class << self
    def log_event(event_name, *args)
      if Marty::Util.logger.respond_to?(event_name)
        Marty::Util.logger.send(
          event_name,
          args[0]
        )
      end

      log(event_name, *args)
    end

    def debug(*args)
      log_event(:debug, *args)
    end

    def info(*args)
      log_event(:info, *args)
    end

    def warn(*args)
      log_event(:warn, *args)
    end

    def error(*args)
      log_event(:error, *args)
    end

    def fatal(*args)
      log_event(:fatal, *args)
    end

    def unknown(*args)
      log_event(:unknown, *args)
    end

    def log(type, message, details = nil)
      Marty::Log.write_log(type, message, details)
    end

    def with_logging(error_message, error_data)
      yield
    rescue StandardError => e
      error(
        error_message,
        'message' => e.message,
        'data' => error_data
      )

      raise "#{error_message}: #{e.message}"
    end
  end
end
