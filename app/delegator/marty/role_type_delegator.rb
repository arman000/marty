module Marty
  module RoleTypeDelegator
    class << self
      role_type_klass = Rails.application.config.marty.role_type
      delegate_missing_to role_type_klass || ::Marty::RoleType
    end
  end
end
