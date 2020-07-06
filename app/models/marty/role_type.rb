class Marty::RoleType < Marty::Base
  extend Marty::PgEnum

  VALUES = [
    'admin',
    'user_manager',
    'dev',
    'viewer',
    'data_grid_editor'
  ]

  class << self
    def from_nice_names(roles)
      klass.get_all.select do |role|
        roles.include?(I18n.t("roles.#{role}", default: role))
      end
    end

    def to_nice_names(roles)
      roles.map do |role|
        I18n.t("roles.#{role}", default: role)
      end
    end
  end
end
