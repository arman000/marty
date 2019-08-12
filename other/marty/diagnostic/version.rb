module Marty::Diagnostic; class Version < Base
  diagnostic_fn do
    begin
      message = `cd #{Rails.root}; git describe --tags --always;`.strip
    rescue StandardError
      message = error('Failed accessing git')
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

  def self.db_schema
      Database.db_schema
  rescue StandardError => e
      error(e.message)
  end
end
end
