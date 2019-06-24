class Marty::RoleType < Marty::Base
  extend Marty::PgEnum

  VALUES = [
    'admin',
    'user_manager',
    'dev',
    'viewer'
  ]
end
