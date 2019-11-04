# frozen_string_literal: true

module Marty
  module CacheAdapters
    class MemoryAndRedis < ::Delorean::Cache::Adapters::Base
      POST = '__RedisCache'

      def initialize(
        size_per_class: 1000,
        redis_url: Rails.application.config.marty.redis_url,
        redis_expires_in: 48.hours
      )
        @size_per_class = size_per_class

        @redis_adapter = ::Marty::CacheAdapters::Redis.new(
          redis_url: redis_url,
          expires_in: redis_expires_in
        )

        @memory_adapter = ::Marty::CacheAdapters::McflyRubyCache.new(
          size_per_class: size_per_class
        )
      end

      def cache_item(klass:, cache_key:, item:)
        @redis_adapter.cache_item(
          klass: klass,
          cache_key: cache_key,
          item: item
        )

        @memory_adapter.cache_item(
          klass: klass,
          cache_key: cache_key,
          item: item
        )
      end

      # When cache is found in local memory, we simply return the cached item.
      # Otherwise we look into Redis, if item is cached there,
      # we copy it to local memory to speed up future lookups.
      def fetch_item(klass:, cache_key:, default: nil)
        memory_item = @memory_adapter.fetch_item(
          klass: klass,
          cache_key: cache_key,
          default: default
        )

        return memory_item if memory_item != default

        redis_item = @redis_adapter.fetch_item(
          klass: klass,
          cache_key: cache_key,
          default: default
        )

        return default if redis_item == default

        @memory_adapter.cache_item(
          klass: klass,
          cache_key: cache_key,
          item: redis_item
        )

        redis_item
      end

      def cache_key(klass:, method_name:, args:)
        r = ["#{klass.name}#{POST}", method_name] + args.map do |arg|
          arg.respond_to?(:id) ? arg.id : arg

          arg
        end.freeze

        Marshal.dump r
      end

      def clear!(klass:)
        @redis_adapter.clear!(klass: klass)
        @memory_adapter.clear!(klass: klass)
      end

      def clear_all!
        @redis_adapter.clear_all!
        @memory_adapter.clear_all!
      end

      def cache_item?(klass:, method_name:, args:)
        !Mcfly.is_infinity(args&.first)
      end
    end
  end
end
