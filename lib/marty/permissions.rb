module Marty
  module Permissions
    ALL_PERMS = Set.new Rails.configuration.marty.roles

    # set of roles for the current user
    def cm_permissions
      roles = Mcfly.whodunnit.roles rescue []
      Set.new(roles.map {|r| r.name.to_sym})
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
