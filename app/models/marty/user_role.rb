class Marty::UserRole < Marty::Base
  validates :user_id, uniqueness: { scope: [:role] }
  validates :user_id, :role, presence: true

  belongs_to :user

  class << self
    def from_nice_names(roles)
      role_values.select do |role|
        roles.include?(I18n.t("roles.#{role}", default: role))
      end
    end

    def role_type
      Rails.application.config.marty.role_type || ::Marty::RoleType
    end

    def role_values
      role_type.values
    end

    def to_nice_names(roles)
      roles.map do |role|
        I18n.t("roles.#{role}", default: role)
      end
    end
  end
end
