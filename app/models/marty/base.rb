class Marty::Base < ActiveRecord::Base
  self.table_name_prefix = "marty_"
  self.abstract_class = true

  def self.mcfly_pt(pt)
    tb = self.table_name
    self.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end
  MCFLY_PT_SIG = [1, 1]

  # FIXME: hacky signatures for AR queries
  COUNT_SIG    = [0, 0]
  DISTINCT_SIG = [0, 100]
  FIRST_SIG    = [0, 1]
  GROUP_SIG    = [1, 100]
  JOINS_SIG    = [1, 100]
  LAST_SIG     = [0, 1]
  LIMIT_SIG    = [1, 1]
  NOT_SIG      = [1, 100]
  ORDER_SIG    = [1, 100]
  PLUCK_SIG    = [1, 100]
  SELECT_SIG   = [1, 100]
  WHERE_SIG    = [0, 100]
end
