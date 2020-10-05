module Marty
  module Rules
    class DbLoader
      attr_reader :package_name

      def initialize(package_name:)
        @package_name = package_name
      end

      def package(pt:)
        p = Marty::Rules::Package.where(
          name: package_name
        ).find_by(starts_at: pt)

        return unless p

        { 'starts_at' => p.starts_at, 'script' => p.script }
      end

      def closest_package_pt(pt:)
        Marty::Rules::Package.where(
          name: package_name
        ).where("starts_at < date_trunc('second', ?::timestamp)", pt).maximum('starts_at')
      end
    end
  end
end
