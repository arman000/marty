class Marty::Diagnostic::Aws::Error < StandardError
  attr_accessor :object

  def initialize(action, object = nil)
    super("#{action}: #{object.try(:[], 'Message') || 'Unexpected Response'}")
    self.object = object
  end
end
