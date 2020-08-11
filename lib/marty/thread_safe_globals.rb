module Marty
  module ThreadSafeGlobals
    class << self
      def global_vars
        @global_vars ||= {}
      end

      def promise_id
        global_vars.dig(Thread.current.object_id, 'promise_id')
      end

      def promise_id=(id)
        global_vars[Thread.current.object_id] ||= {}
        global_vars[Thread.current.object_id]['promise_id'] = id
      end
    end
  end
end
