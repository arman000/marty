module Marty
  module Diagnostic
    class Configuration < Marty::Base
      DEFAULT_TIMEOUT = 1

      self.table_name = :marty_diagnostic_configurations

      belongs_to :report

      delegate :generate, to: :diagnostic
      delegate :aggregatable, to: :diagnostic

      validates :name, inclusion: { in: Marty::Diagnostic.diagnostics }, uniqueness: true
      validates :timeout, numericality: { greater_than: 0, less_than_or_equal_to: 30 }

      before_validation -> { self.timeout = DEFAULT_TIMEOUT }, unless: :timeout?

      def diagnostic
        name.constantize
      end
    end
  end
end
