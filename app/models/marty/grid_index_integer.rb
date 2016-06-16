class Marty::GridIndexInteger < Marty::Base
  validates_presence_of :created_dt, :data_grid_id, :attr, :index
end
