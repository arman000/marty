module Marty::Permissions
  # Call using following format
  #   has_marty_permissions   create: [:dev, :admin],
  #                           read: :any,
  #                           update: :admin,
  #                           delete: []
  #
  # :any gives permission to the action if user belongs to at least 1 role
  def has_marty_permissions(attrs)
    raise 'bad attrs' unless attrs.is_a?(Hash)

    define_singleton_method(:marty_permissions) { attrs }
  end

  def current_user_roles
    user_roles = Mcfly.whodunnit.user_roles rescue []
    user_roles.map { |r| r.role.to_sym }.to_set
  end

  def can_perform_action?(action)
    return false unless respond_to?(:marty_permissions)

    roles = current_user_roles
    roles = roles << :any if has_any_perm?

    aroles = marty_permissions[action.to_sym] || []
    # TODO: Use code below when switching to Ruby 2.1
    # Set[ *aroles].intersect? roles.to_set
    !(Set[*aroles] & roles.to_set).empty?
  end

  def can_perform_actions
    return [] unless respond_to?(:marty_permissions)

    roles = current_user_roles
    roles = roles << :any if has_any_perm?

    marty_permissions.map do |action, aroles|
      # TODO: Use code below when switching to Ruby 2.1
      # action if Set[ *aroles].intersect? roles.to_set
      action unless (Set[*aroles] & roles.to_set).empty?
    end.compact
  end

  def has_any_perm?
    current_user_roles.any?
  end

  def has_perm?(role)
    current_user_roles.member? role.to_sym
  end

  # FIXME: for backwards compatibility returns true
  # if permission is not specified in has_marty_permissions

  NETZKE_ENDPOINTS = [:create, :read, :update, :delete].freeze

  def can_call_endpoint?(endpoint)
    # Netzke endpoints access is controlled by Netzke permissions
    return true if NETZKE_ENDPOINTS.include?(endpoint.to_sym)

    return true unless respond_to?(:marty_permissions)
    return true unless marty_permissions.key?(endpoint.to_sym)

    can_perform_action?(endpoint)
  end

  # FIXME: hack to override Netzke invoke endpoint
  # for classes with Marty::Permissions
  def self.extended(mod)
    mod.class_exec do
      def invoke_endpoint(endpoint, params, configs = [])
        return super(endpoint, params, configs) if self.class.can_call_endpoint?(endpoint)

        self.client = Netzke::Core::EndpointResponse.new
        client.netzke_notify 'Permission Denied'
        client
      end
    end
  end
end
