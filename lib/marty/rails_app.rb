module Marty
  module RailsApp
    RAILS_VERSION_5 = '5.2.0'
    RAILS_VERSION_6 = '6.0.0'

    class << self
      def application_name(with_env: false, constantize: false)
        name = if rails_version_ge?(RAILS_VERSION_6)
                 Rails.application.class.module_parent_name
               else
                 Rails.application.class.parent_name
               end

        if with_env
          e = Rails.env

          return application_name if e.production?

          application_name.titleize + " - #{e.capitalize}"
        elsif constantize
          application_name.constantize
        else
          name
        end
      end

      def application_name_with_env
        application_name(with_env: true)
      end

      def application_name_constant
        application_name(constantize: true)
      end

      def needs_migration?
        return ActiveRecord::Base.connection.migration_context.needs_migration? if
               rails_version_ge?(RAILS_VERSION_5)

        ActiveRecord::Migrator.needs_migration?
      end

      def parameter_filter_class
        return ActiveSupport::ParameterFilter if rails_version_ge?(RAILS_VERSION_6)

        ActionDispatch::Http::ParameterFilter
      end

      private

      # Helper function which returns if the Rails version is greater than or
      # equal to the one given.
      #
      # @param version_to_compare [String] the version string to compare the
      #   current {Rails.version} to
      #
      # @return [Boolean]
      def rails_version_ge?(version_to_compare)
        @current_rails_version ||= ::Gem::Version.new(Rails.version)
        other_version = ::Gem::Version.new(version_to_compare)

        @current_rails_version >= other_version
      end
    end
  end
end
