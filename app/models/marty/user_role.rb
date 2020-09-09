class Marty::UserRole < Marty::Base
  validates :user_id, uniqueness: { scope: [:role] }
  validates :user_id, :role, presence: true

  belongs_to :user

  mattr_reader :role_type_klass

  class << self
    def from_nice_names(roles)
      role_values.select do |role|
        roles.include?(I18n.t("roles.#{role}", default: role))
      end
    end

    def role_type
      return role_type_klass if role_type_klass

      klass = Rails.application.config.marty.role_type || ::Marty::RoleType

      raise "'#{klass}' must be a Class" unless klass.is_a?(Class)

      [:values, :table_name].each do |m|
        raise "'#{klass}' missing '#{m}' method" unless klass.respond_to?(m)
      end

      role_type_klass = klass
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
