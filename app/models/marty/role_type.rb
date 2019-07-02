class Marty::RoleType < Marty::Base
  extend Marty::PgEnum

  VALUES = [
    'admin',
    'user_manager',
    'dev',
    'viewer',
    'data_grid_editor'
  ]

  def self.from_nice_names(roles)
    Marty::RoleType.get_all.select do |role|
      roles.include?(I18n.t("roles.#{role}", default: role))
    end
  end

  def self.to_nice_names(roles)
    roles.map do |role|
      I18n.t("roles.#{role}", default: role)
    end
  end
end
