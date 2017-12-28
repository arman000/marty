class Diagnostic::Version < Diagnostic::Base
  def self.generate
    pack do
      begin
        message = `cd #{Rails.root.to_s}; git describe --tags --always;`.strip
      rescue
        message = error("Failed accessing git")
      end
      {
        'Marty'    => Marty::VERSION,
        'Delorean' => Delorean::VERSION,
        'Mcfly'    => Mcfly::VERSION,
        'Git'      => message,
      }
    end
  end
end
