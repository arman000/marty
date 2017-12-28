class Diagnostic::Environment < Diagnostic::Base
  def self.generate
    pack do
      rbv = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})"
      {
        'Environment'             => Rails.env,
        'Rails'                   => Rails.version,
        'Netzke Core'             => Netzke::Core::VERSION,
        'Netzke Basepack'         => Netzke::Basepack::VERSION,
        'Ruby'                    => rbv,
        'RubyGems'                => Gem::VERSION,
        'Database Adapter'        => Diagnostic::Database.db_adapter_name,
        'Database Server'         => Diagnostic::Database.db_server_name,
        'Database Version'        => db_version,
        'Database Schema Version' => db_schema
      }
    end
  end

  def self.db_version
    begin
      Diagnostic::Database.db_version
    rescue => e
      error(e.message)
    end
  end

  def self.db_schema
    begin
      Diagnostic::Database.db_schema
    rescue => e
      error(e.message)
    end
  end
end
