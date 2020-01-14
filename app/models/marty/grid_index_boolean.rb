class Marty::GridIndexBoolean < Marty::Base
  validates :created_dt, :data_grid_id, :attr, :index, presence: true
  validates :key, inclusion: { in: [true, false, nil] }
end
