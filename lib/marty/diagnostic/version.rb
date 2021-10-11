module Marty::Diagnostic
  class Version < Base
    diagnostic_fn do
      versions.merge(git)
    end

    class << self
      def description
        <<~TEXT
          Returns application, git, and submodule versions.
        TEXT
      end

      def git
          { 'Root Git' => Git.tag }.merge(Git.submodules)
      rescue StandardError
          { 'Root Git' => error('Failed accessing git') }
      end

      def versions
        {
          'Marty'                   => Marty::VERSION,
          'Delorean'                => Delorean::VERSION,
          'Mcfly'                   => Mcfly::VERSION,
          'Rails'                   => Rails.version,
          'Netzke Core'             => Netzke::Core::VERSION,
          'Netzke Basepack'         => Netzke::Basepack::VERSION,
          'Ruby'                    => rbv,
          'RubyGems'                => ::Gem::VERSION,
          'Database Schema Version' => db_schema,
          'Postgres'                => Database.db_version,
          'Environment'             => Rails.env,
        }
      end

      def rbv
        "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      end

      def db_schema
          Database.db_schema
      rescue StandardError => e
          error(e.message)
      end
    end
  end
end
