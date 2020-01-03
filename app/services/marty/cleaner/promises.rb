module Marty
  module Cleaner
    module Promises
      class << self
        def call
          ::Marty::Promise.cleanup(false)
        end
      end
    end
  end
end
