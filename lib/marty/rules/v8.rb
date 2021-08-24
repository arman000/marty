module Marty
  module Rules
    class V8
      attr_reader :packages, :name, :v8, :loader, :logger, :memory_limit_mb,
                  :timeout_seconds

      def initialize(name:, packages:, loader:, logger:, memory_limit_mb: 200,
                     timeout_seconds: 30)
        @name = name

        @loader = loader
        @logger = logger

        @memory_limit_mb = memory_limit_mb
        @timeout_seconds = timeout_seconds

        @v8 = create_v8

        packages.each do |package|
          script_str = js_script(
            pt: package['starts_at'].to_s,
            script: package['script'],
            metadata: package['metadata']
          )
          v8.eval(script_str)
        end

        @packages = packages.map { |package| package['starts_at'] }
      end

      def call(pt:, fn: 'call', args:)
        v8.call(fn, pt.to_s, args)
      rescue MiniRacer::V8OutOfMemoryError => e
        # FIXME: should we log only if second attempt failed?
        logger.log(
          'error',
          "Marty::Rules::Runtime error: #{e.message}",
          {
            package_name: name, error_class: e.class.name,
            backtrace: e.backtrace, pt: pt, fn: fn, args: args
          }
        )

        # Recreate V8, load package and try again
        recreate_v8

        package = loader.package(pt: loader.closest_package_pt(pt: pt))
        load_package(package: package)

        v8.call(fn, pt.to_s, args)
      rescue MiniRacer::ScriptTerminatedError => e
        logger.log(
          'error',
          "Marty::Rules::Runtime error: #{e.message}",
          { package_name: name, error_class: e.class.name,
            backtrace: e.backtrace, pt: pt, fn: fn, args: args }
        )

        raise e
      end

      def create_v8
        v8 = MiniRacer::Context.new(
          max_memory: memory_limit_mb * 1_000_000,
          timeout: timeout_seconds * 1_000
        )

        v8.eval(INITIAL_JS_SCRIPT)
        v8
      end

      def recreate_v8
        dispose
        @v8 = create_v8
      end

      def load_package(package:)
        script_str = js_script(
          pt: package['starts_at'].to_s, script: package['script'],
          metadata: package['metadata'])
        v8.eval(script_str)
        @packages += [package['starts_at']]

        true
      rescue MiniRacer::V8OutOfMemoryError => e
        recreate_v8
        v8.eval(script_str)
        @packages += [package['starts_at']]

        true
        # FIXME: sometimes it would throw ScriptTerminatedError insetad of OutOfMemory
        # In that case we recreate v8 and try to load the script again
      rescue MiniRacer::ScriptTerminatedError => e
        recreate_v8
        v8.eval(script_str)
        @packages += [package['starts_at']]

        true
      end

      def min_pt
        packages.min
      end

      def dispose
        v8.dispose
        @packages = []
      end

      def js_script(pt:, script:, metadata:)
        # Zeus returns a bundle within `var zeus_bundled_code = ...`.
        # We can use that var in order to access the package.
        <<~JS
          var pt = "#{pt}";
          #{script};
          metadata_h[pt] = #{metadata.to_json || {}};
          scripts[pt] = zeus_bundled_code;
        JS
      end

      # FIXME: too much date parsing?
      INITIAL_JS_SCRIPT = <<~JS
        var scripts = {};
        var metadata_h = {};

        var getPt = (pt) => {
          const pts = Object.keys(scripts);
          const filteredPts = pts.filter((keyPt) => {
            return Date.parse(keyPt) < Date.parse(pt)
          });

          const sortedPts = filteredPts.sort((date1, date2) => {
            return Date.parse(date2) - Date.parse(date1)
          });

          return sortedPts[0];
        }
        var metadata = (pt) => {
          var scriptPt = getPt(pt);
          return metadata_h[scriptPt];
        };
        var call = (pt, hash) => {
          var scriptPt = getPt(pt);
          return scripts[scriptPt].call(hash);
        }
      JS
    end
  end
end
