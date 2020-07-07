class Marty::RoleType < Marty::Base
  extend Marty::PgEnum

  VALUES = [
    'admin',
    'user_manager',
    'dev',
    'viewer',
    'data_grid_editor'
  ]
end
