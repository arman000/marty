module Gemini
  module PromiseHook
    module TestHook
      def self.run(opts)
        Marty::Logger.log('TestHook', 'was called')
      end
    end
  end
end
