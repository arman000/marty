class Marty::SqlRule < Marty::BaseRule
  self.abstract_class = true

  def self.generate_exclusions(exclusions)
    Marty::Exclusion.new(exclusions)
  end

end
