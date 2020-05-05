module Marty
  module Cleaner
    module Logs
      class << self
        def call(days)
          Marty::Log.where(
            'timestamp < ?', Time.zone.today - days.to_i.days
          ).delete_all
        end
      end
    end
  end
end
