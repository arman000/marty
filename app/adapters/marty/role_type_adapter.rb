module Marty
  module RoleTypeAdapter
    class << self
      role_type_klass = Rails.application.config.marty.role_type_klass
      delegate_missing_to role_type_klass || ::Marty::RoleType
    end
  end
end
