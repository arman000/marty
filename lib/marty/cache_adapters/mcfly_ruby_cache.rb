module Marty
  module CacheAdapters
    class McflyRubyCache < ::Delorean::Cache::Adapters::RubyCache
      def cache_item?(klass:, method_name:, args:)
        !Mcfly.is_infinity(args&.first)
      end
    end
  end
end
