module Marty
  module Rules
    class MartyLogger
      attr_reader :package_name

      def initialize(package_name:)
        @package_name = package_name
      end

      def log(*args)
        ::Marty::Logger.log_event(*args)
      end
    end
  end
end
