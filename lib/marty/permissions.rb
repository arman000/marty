module Marty
  module Permissions
    # Make sure there are admin and user_manager roles,
    # even if hosting app doesn't define them
    REQ_ROLES = [:admin, :user_manager]
    ALL_ROLES = (Set.new Rails.configuration.marty.roles.clone).merge(REQ_ROLES)
    ACTIONS = Set.new [:create, :read, :update, :delete] # CRUD

    # Call using following format
    #   has_marty_permissions	create: [:dev, :admin],
    #				read: :any,
    #				update: :admin,
    #				delete: :none
    #
    # Allowed actions are only :create, :read, :update, :delete
    # Roles can be passed in as a symbol or array of symbols
    #
    # :any gives permission to the action if user belongs to at least 1 role
    # :none overrides any other roles
    #    e.g. delete: [:none, :admin] would return false when calling
    #    can_allow_action? even if the user belong to the admin role
    def has_marty_permissions(attrs)
      raise "bad attrs" unless attrs.is_a?(Hash)
      raise "unknown action - only create/read/update/delete allowed" unless
        attrs.keys.to_set.subset? ACTIONS
      raise "unknown role" unless
        attrs.values.flatten.to_set.subset? (ALL_ROLES << :any << :none)

      #klass = self.to_s
      #return "#{klass} with #{attrs.inspect}"
      self.define_singleton_method(:marty_permissions) { attrs }
    end

    def current_user_roles
      roles = Mcfly.whodunnit.roles rescue []
      Set.new(roles.map {|r| r.name.to_sym})
    end

    def can_perform_action?(action)
      roles = self.current_user_roles
      roles << :any if self.has_any_perm?

      allow = false

      if self.respond_to?(:marty_permissions)
        perms = self.marty_permissions
        result = []
        result = (result << perms.fetch(action.to_sym)).flatten if
          perms.include?(action.to_sym)

        result.each {|r| allow ||= roles.include? r} unless
          result.include?(:none)
        #puts "#{self.to_s} #{action} - #{allow}"
      end
      allow
    end

    # generate has_xxx_perm? methods for all permissions.
    Rails.configuration.marty.roles.each { |role|
      define_method("has_#{role}_perm?") do
        current_user_roles.member? role
      end
    }

    def has_any_perm?
      !(current_user_roles & ALL_ROLES).empty?
    end
  end
end
