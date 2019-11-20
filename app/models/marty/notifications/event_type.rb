module Marty
  module Notifications
    class EventType < Marty::Base
      extend Marty::PgEnum

      VALUES = Set[
        'API reached the limit'
      ]
    end
  end
end
