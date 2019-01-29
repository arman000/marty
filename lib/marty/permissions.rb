module Marty::Permissions
  # Make sure there are admin and user_manager roles,
  # even if hosting app doesn't define them
  REQ_ROLES = [:admin, :user_manager]
  ALL_ROLES = Rails.configuration.marty.roles.to_set.merge(REQ_ROLES)

  # Call using following format
  #   has_marty_permissions   create: [:dev, :admin],
  #                           read: :any,
  #                           update: :admin,
  #                           delete: []
  #
  # :any gives permission to the action if user belongs to at least 1 role
  def has_marty_permissions(attrs)
    raise "bad attrs" unless attrs.is_a?(Hash)
    raise "unknown role" unless
      attrs.values.flatten.to_set.subset? (ALL_ROLES << :any)

    self.define_singleton_method(:marty_permissions) { attrs }
  end

  def current_user_roles
    roles = Mcfly.whodunnit.roles rescue []
    roles.map { |r| r.name.to_sym }.to_set
  end

  def can_perform_action?(action)
    return false unless self.respond_to?(:marty_permissions)

    roles = self.current_user_roles
    roles = roles << :any if self.has_any_perm?

    aroles = self.marty_permissions[action.to_sym] || []
    # TODO: Use code below when switching to Ruby 2.1
    # Set[ *aroles].intersect? roles.to_set
    (Set[*aroles] & roles.to_set).length > 0
  end

  def can_perform_actions
    return [] unless self.respond_to?(:marty_permissions)

    roles = self.current_user_roles
    roles = roles << :any if self.has_any_perm?

    self.marty_permissions.map do |action, aroles|
      # TODO: Use code below when switching to Ruby 2.1
      # action if Set[ *aroles].intersect? roles.to_set
      action if (Set[*aroles] & roles.to_set).length > 0
    end.compact
  end

  # generate has_xxx_perm? methods for all permissions.
  Rails.configuration.marty.roles.each do |role|
    define_method("has_#{role}_perm?") do
      current_user_roles.member? role
    end
  end

  def has_any_perm?
    !(current_user_roles & ALL_ROLES).empty?
  end
end
