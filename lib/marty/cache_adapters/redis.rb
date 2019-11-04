# frozen_string_literal: true

require 'redis'

module Marty
  module CacheAdapters
    class Redis < ::Delorean::Cache::Adapters::Base
      POST = '__RedisCache'

      def initialize(
        size_per_class: 1000,
        redis_url: Rails.application.config.marty.redis_url,
        expires_in: 48.hours
      )
        @redis = ::Redis.new(url: "redis://#{redis_url}")
        @expires_in = expires_in
      end

      def cache_item(klass:, cache_key:, item:)
        @redis.set(
          cache_key,
          Marshal.dump(item),
          ex: @expires_in.seconds.to_i
        )
      end

      def fetch_item(klass:, cache_key:, default: nil)
        r = @redis.get(cache_key)

        return default if r.nil?

        Marshal.load(r)
      end

      def cache_key(klass:, method_name:, args:)
        r = ["#{klass.name}#{POST}", method_name] + args.map do |arg|
          next arg.id if arg.respond_to?(:id)

          arg
        end.freeze

        Marshal.dump r
      end

      def clear!(klass:)
        keys = @redis.keys("*#{klass.name}#{POST}*")
        @redis.pipelined do
          keys.each do |key|
            @redis.del key
          end
        end
      end

      def clear_all!
        @redis.flushall
      end

      def cache_item?(klass:, method_name:, args:)
        !Mcfly.is_infinity(args&.first)
      end
    end
  end
end
