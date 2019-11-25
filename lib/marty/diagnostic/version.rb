module Marty::Diagnostic
  class Version < Base
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

        git_tag = `cd #{Rails.root}; git describe --tags --always;`.strip
        git = { 'Root Git' => git_tag }.merge(submodules)
      rescue StandardError
        git = { 'Root Git' => error('Failed accessing git') }
      end
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      {
        'Marty'                   => Marty::VERSION,
        'Delorean'                => Delorean::VERSION,
        'Mcfly'                   => Mcfly::VERSION,
        'Rails'                   => Rails.version,
        'Netzke Core'             => Netzke::Core::VERSION,
        'Netzke Basepack'         => Netzke::Basepack::VERSION,
        'Ruby'                    => rbv,
        'RubyGems'                => Gem::VERSION,
        'Database Schema Version' => db_schema,
        'Environment'             => Rails.env,
      }.merge(git)
    end

    def self.db_schema
        Database.db_schema
    rescue StandardError => e
        error(e.message)
    end
  end
end
