module Marty::Diagnostic
  class ObjectSizes < Base
    def self.description
      <<~TEXT
        Lists sizes of objects in database.
      TEXT
    end

    diagnostic_fn aggregatable: false do
      Database.sizes.to_h
    end
  end
end
