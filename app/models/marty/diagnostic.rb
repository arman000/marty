class Diagnostic
  attr_accessor :name, :status, :details, :aggregate, :nodes

  def initialize(opts = {})
    @name, @details = opts[:name], opts[:details]
    @nodal = !opts[:nodes]
    @aggregate = opts[:aggregate]
    @status = @details.all?{|x| x.status}
  end

  def status_text
    case status
    when true
      "Passed"
    when false
      "Failed"
    else
      "Unknown"
    end
  end
end
