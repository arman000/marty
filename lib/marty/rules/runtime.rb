require 'marty/rules/errors/package_not_found'
require 'marty/rules/db_loader'
require 'marty/rules/marty_logger'

module Marty
  module Rules
    class Runtime
      attr_reader :package_name, :current_v8, :historical_v8, :loader, :logger, :memory_limit_mb, :timeout_seconds

      def initialize(
        package_name:,
        logger: Marty::Rules::MartyLogger.new(package_name: package_name),
        loader: Marty::Rules::DbLoader.new(package_name: package_name),
        memory_limit_mb: 200,
        timeout_seconds: 30
      )

        @package_name = package_name

        @loader = loader
        @logger = logger

        @memory_limit_mb = memory_limit_mb
        @timeout_seconds = timeout_seconds

        @current_v8 = Marty::Rules::V8.new(
          name: "#{package_name}: current",
          packages: [
            package(pt: closest_package_pt(pt: Time.zone.now))
          ].compact,
          memory_limit_mb: memory_limit_mb,
          timeout_seconds: timeout_seconds,
          loader: loader,
          logger: logger
        )

        @historical_v8 = Marty::Rules::V8.new(
          name: "#{package_name}: historical",
          packages: [],
          memory_limit_mb: memory_limit_mb,
          timeout_seconds: timeout_seconds,
          loader: loader,
          logger: logger
        )
      end

      def operate(pt:, args:)
        closest_pt = closest_package_pt(pt: pt)

        return package_not_found(pt: pt) unless closest_pt

        # new 'infinity' package has arrived and is being called
        if current_v8.min_pt.nil? || closest_pt > current_v8.min_pt
          # Recreate a new "infinity" V8 for the package
          current_v8.dispose

          @current_v8 = Marty::Rules::V8.new(
            name: "#{package_name}: current",
            packages: [package(pt: closest_pt)],
            memory_limit_mb: memory_limit_mb,
            timeout_seconds: timeout_seconds,
            loader: loader,
            logger: logger
          )

          yield(current_v8, pt, args)
        elsif current_v8.packages.include?(closest_pt)
          yield(current_v8, pt, args)
        elsif historical_v8.packages.include?(closest_pt)
          yield(historical_v8, pt, args)
        else
          historical_v8.load_package(
            package: package(pt: closest_pt)
          )
          yield(historical_v8, pt, args)
        end
      end

      def call(pt:, hash:)
        operate(pt: pt, args: hash) do |context, ipt, args|
          context.call(pt: ipt, args: args)
        end
      end

      def metadata(pt:)
        operate(pt: pt, args: nil) do |context, ipt|
          context.call(pt: ipt, fn: 'metadata', args: ipt)
        end
      end

      def closest_package_pt(pt:)
        loader.closest_package_pt(pt: pt)
      end

      def package(pt:)
        loader.package(pt: pt)
      end

      def package_not_found(pt:)
        raise(
          ::Marty::Rules::Errors::PackageNotFound,
          "Package #{package_name} with starting date before #{pt} was not found"
        )
      end
    end
  end
end
