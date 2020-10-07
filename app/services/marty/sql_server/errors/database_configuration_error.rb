# frozen_string_literal: true

module Marty
  module SqlServer
    module Errors
      class DatabaseConfigurationError < StandardError
        def initialize(prefix)
          config_name = "#{prefix}#{Rails.env}"
          msg = "'#{config_name}' is not a defined database configuration"
          super(msg)
        end
      end
    end
  end
end
