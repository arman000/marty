module Marty::Diagnostic
  class Version < Base
    GITLAB_CI_INCLUDE_HASH = {
      'project' => 'cm_tech/cm_gitlab_ci',
      'file' => '/.gitlab/ci/defaults.yml'
    }.freeze

    def self.git_tag
      git_tag = `cd #{Rails.root}; git describe --tags --always --abbrev=7;`.strip
      git_datetime = `cd #{Rails.root}; git log -1 --format=%cd;`.strip
      "#{git_tag} (#{git_datetime})"
    end

    diagnostic_fn do
      begin
        submodules = `cd #{Rails.root}; git submodule`.split("\n").map do |s|
          sha, path, tag = s.split
          name = File.basename(path)
          {
            "#{name}_sha".titleize => sha[0..7],
            "#{name}_tag".titleize => tag,
          }
        end.reduce(&:merge) || {}

        git = { 'Root Git' => git_tag }.merge(submodules)
      rescue StandardError
        git = { 'Root Git' => error('Failed accessing git') }
      end

      versions.merge(git)
    end

    def self.versions
      {
        'Marty'                   => Marty::VERSION,
        'Delorean'                => Delorean::VERSION,
        'Mcfly'                   => Mcfly::VERSION,
        'CM Shared'               => get_cm_shared,
        'Rails'                   => Rails.version,
        'Netzke Core'             => Netzke::Core::VERSION,
        'Netzke Basepack'         => Netzke::Basepack::VERSION,
        'Ruby'                    => rbv,
        'RubyGems'                => Gem::VERSION,
        'Database Schema Version' => db_schema,
        'Postgres'                => Database.db_version,
        'Shared GitLab CI'        => check_gitlab_ci,
        'Environment'             => Rails.env,
      }
    end

    def self.rbv
      "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
    end

    def self.db_schema
        Database.db_schema
    rescue StandardError => e
        error(e.message)
    end

    # If defined in the current context, get the version.
    # If not, check to see if Bundler knows about `cm_shared`
    def self.get_cm_shared
      CmShared::VERSION
    rescue NameError => e
      Bundler.locked_gems.dependencies.key?('cm_shared')
    rescue StandardError => e
      e.message
    end

    def self.check_gitlab_ci
      gitlab_ci = YAML.load_file('.gitlab-ci.yml')
      includes = gitlab_ci.fetch('include')
      includes.any? { |incl| incl == GITLAB_CI_INCLUDE_HASH }
    rescue Errno::ENOENT
      '.gitlab-ci.yml not found'
    rescue StandardError => e
      e.message
    end
  end
end
