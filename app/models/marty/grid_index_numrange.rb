class Marty::GridIndexNumrange < Marty::Base
  validates :created_dt, :data_grid_id, :attr, :index, presence: true
end
