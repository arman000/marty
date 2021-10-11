module Marty
  module Diagnostic
    class Collection < Base
      class_attribute :diagnostics

      self.diagnostics = []
      self.status_only = true

      class << self
        def generate
          raise 'No diagnostics assigned to collection.' if diagnostics.empty?

          diagnostics.map(&:generate).reduce(:deep_merge)
        end
      end
    end
  end
end
