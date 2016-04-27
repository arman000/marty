class Marty::GridIndexBoolean < Marty::Base
  validates_presence_of :created_dt, :data_grid_id, :attr, :index
  validates_inclusion_of :key, in: [true, false]
end
