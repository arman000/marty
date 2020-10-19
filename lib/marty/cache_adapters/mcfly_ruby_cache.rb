module Marty
  module CacheAdapters
    class McflyRubyCache < ::Delorean::Cache::Adapters::RubyCache
      def cache_item?(klass:, method_name:, args:)
        !Mcfly.is_infinity(args&.first)

        # FIXME: uncomment and make sure it works with strings
        # return false if future_pt?(args&.first)
        #
        # true
      end

      def future_pt?(time_or_str)
        return true if Mcfly.is_infinity(time_or_str)

        return time_or_str.future? if time_or_str.respond_to?(:future?)

        false
      end
    end
  end
end
