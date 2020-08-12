module Marty
  module MaintenanceWindow
    # This will ensure that we are in a maintenance window when
    # provided with a Marty::Config key that matches the following format
    # { day: 'saturday', range: ['00:00', '24:00'] }
    HASH_KEYS = ['day', 'range'].freeze
    DAYNAMES = Date::DAYNAMES.map(&:downcase).to_set

    class << self
      def call(config_key)
        window = ::Marty::Config.fetch(config_key)
        raise "'#{config_key}' is not a hash'" unless window.is_a?(Hash)

        day, range = HASH_KEYS.map do |k|
          raise "'#{k}' is missing from '#{config_key}'" unless window.key?(k)

          window[k]
        end

        raise '\'day\' must be a String' unless day.is_a?(String)

        pday = day.downcase
        raise '\'day\' must be a valid day of the week' unless
          DAYNAMES.member?(pday) || (pday == '*')

        unless pday == '*' || Time.zone.now.send("#{pday}?")
          raise "#{name.demodulize} can only be called on "\
                "#{pday.capitalize}"
        end

        raise '\'range\' must be an array of length 2' unless
          range.is_a?(Array) && range.size == 2

        prange = range.map { |r| Time.zone.parse(r) }
        raise 'invalid range specified' unless prange.all?

        raise "Current time not within maintenance window: #{prange}" unless
          Time.zone.now.between?(prange.first, prange.second)

        window.merge('range' => prange, 'day' => pday)
      end
    end
  end
end
