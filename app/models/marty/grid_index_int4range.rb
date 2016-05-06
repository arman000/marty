class Marty::GridIndexInt4range < Marty::Base
  validates_presence_of :created_dt, :data_grid_id, :attr, :key, :index
end
