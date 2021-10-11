module Marty
  module Diagnostic
    class Report < Marty::Base
      self.table_name = :marty_diagnostic_reports
      has_many :configurations, dependent: :nullify
    end
  end
end
