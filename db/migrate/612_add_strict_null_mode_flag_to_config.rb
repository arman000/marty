class AddStrictNullModeFlagToConfig < ActiveRecord::Migration[5.1]
  def up
    Marty::Config['ENFORCE_DATA_GRID_STRICT_NULL_MODE'] ||= false
  end

  def down
    announce('No-op on AddStrictNullModeFlagToConfig.down')
  end
end
