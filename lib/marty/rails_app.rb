module Marty
  module RailsApp
    class << self
      def application_name
        if Gem::Version.new(Rails.version) >= Gem::Version.new('6.0.0')
          Rails.application.class.module_parent_name
        else
          Rails.application.class.parent_name
        end
      end

      def application_name_with_env
        e = Rails.env

        return application_name if e.production?

        application_name.titleize + " - #{e.capitalize}"
      end

      def needs_migration?
        if Gem::Version.new(Rails.version) >= Gem::Version.new('5.2.0')
          ActiveRecord::Base.connection.migration_context.needs_migration?
        else
          ActiveRecord::Migrator.needs_migration?
        end
      end

      def parameter_filter_class
        if Gem::Version.new(Rails.version) >= Gem::Version.new('6.0.0')
          ActiveSupport::ParameterFilter
        else
          ActionDispatch::Http::ParameterFilter
        end
      end
    end
  end
end
