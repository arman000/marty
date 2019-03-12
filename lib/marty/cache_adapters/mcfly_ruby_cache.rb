module Marty
  module CacheAdapters
    class McflyRubyCache < ::Delorean::Cache::Adapters::RubyCache
      def cache_item?(klass:, method_name:, args:)
        ts = args && args.first

        return false if Mcfly.is_infinity(ts)

        true
      end
    end
  end
end
