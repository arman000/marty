module Marty::Diagnostic; class Version < Base
  def self.generate
    pack do
      begin
        message = `cd #{Rails.root.to_s}; git describe --tags --always;`.strip
      rescue
        message = error("Failed accessing git")
      end
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      {
        'Marty'                   => Marty::VERSION,
        'Delorean'                => Delorean::VERSION,
        'Mcfly'                   => Mcfly::VERSION,
        'Git'                     => message,
        'Rails'                   => Rails.version,
        'Netzke Core'             => Netzke::Core::VERSION,
        'Netzke Basepack'         => Netzke::Basepack::VERSION,
        'Ruby'                    => rbv,
        'RubyGems'                => Gem::VERSION,
        'Database Schema Version' => db_schema,
        'Environment'             => Rails.env,
      }
    end
  end

  def self.db_schema
    begin
      Database.db_schema
    rescue => e
      error(e.message)
    end
  end
end
end
