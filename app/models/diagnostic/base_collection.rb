# used to group separate diagnostics into one diagnostic
class Diagnostic::Collection < Diagnostic::ByStatus
  class_attribute :diagnostics
  self.diagnostics = []

  def self.generate
    raise 'No diagnostics assigned to collection.' if diagnostics.empty?
    diagnostics.map{|diagnostic| diagnostic.generate}.reduce(:deep_merge)
  end
end
