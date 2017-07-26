class Gemini::MIDurationType < ActiveRecord::Base
  extend Marty::PgEnum

  VALUES = Set["Annual",
               "NotApplicable",
               "Other",
               "PeriodicMonthly",
               "SingleLifeOfLoan",
               "SingleSpecific",
               "SplitPremium"]

end
