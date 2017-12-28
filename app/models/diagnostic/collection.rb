class Diagnostic::Collection < Diagnostic::Base
  class_attribute :diagnostics
  self.diagnostics = []
  self.status_only = true

  def self.generate
    raise 'No diagnostics assigned to collection.' if diagnostics.empty?
    diagnostics.map{|d| d.generate}.reduce(:deep_merge)
  end
end
