module Marty
  module Secrets
    TERMS = [
      'credential',
      'api_key',
      'api-key',
      'password',
      'secret'
    ]

    module_function

    def terms
      Rails.application.config.marty.secret_terms || TERMS
    end

    def include?(value, term)
      value.to_s.downcase.include?(term.to_s.downcase)
    end

    def any_terms_included?(value)
      terms.any? { |term| include?(value, term) }
    end

    def filter_hash_values(h, additional = nil)
      RailsApp.parameter_filter_class.new(terms + (additional || [])).filter(h)
    end
  end
end
