module Marty
  module Cleaner
    module MaintenanceWindow
      CONFIG_KEY = 'MARTY_CLEANER_MAINTENANCE_WINDOW'
      HASH_KEYS = ['day', 'range']
      DEFAULT_DAY = 'saturday'
      DEFAULT_RANGE = ['00:00', '24:00']
      DAYNAMES = Date::DAYNAMES.map(&:downcase).to_set

      class << self
        def call
          window = ::Marty::Config.fetch(CONFIG_KEY)
          raise "'#{CONFIG_KEY}' is not a hash'" unless window.is_a?(Hash)

          day, range = HASH_KEYS.map do |k|
            raise "'#{k}' is missing from '#{CONFIG_KEY}'" unless window.key?(k)

            window[k] || 'Marty::Cleaner::MaintenanceWindow'\
              "::DEFAULT_#{k.upcase}".constantize
          end

          raise '\'day\' must be a String' unless day.is_a?(String)

          pday = day.downcase
          raise '\'day\' must be a valid day of the week' unless
            DAYNAMES.member?(pday)

          raise "#{name.demodulize} can only be called on "\
                "#{pday.capitalize}" unless Time.zone.now.send("#{pday}?")

          raise '\'range\' must be an array of length 2' unless
            range.is_a?(Array) && range.size == 2

          prange = range.map { |r| Time.zone.parse(r) }
          raise 'invalid range specified' unless prange.all?

          raise "Current time not within maintenance window: #{prange}" unless
            Time.zone.now.between?(prange.first, prange.second)

          window.merge({'range' => prange, 'day' => pday})
        end
      end
    end
  end
end
