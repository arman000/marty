module Marty
  module Permissions
    ALL_PERMS = Set.new Rails.configuration.marty.roles

    def permission_store
      Thread.current[:marty_permission] ||= {}
    end
      
    def cm_permissions
      permission_store[:user_map] ||= {}

      # Hijacking Mcfly whodunnit to find current user.  This will
      # work for tests as well.
      user = Mcfly.whodunnit

      return Set[] unless user

      permission_store[:user_map][user] ||=
        Set.new(user.roles.map { |r| r.name.to_sym} )
    end

    # generate has_xxx_perm? methods for all permissions.
    Rails.configuration.marty.roles.each { |role|
      define_method("has_#{role}_perm?") do
        cm_permissions.member? role
      end
    }

    def has_any_perm?
      !(cm_permissions & ALL_PERMS).empty?
    end
  end
end
