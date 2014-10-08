class Marty::UserView < Marty::CmGridPanel
  has_marty_permissions \
  create: [:admin, :user_manager],
  read: :any,
  update: [:admin, :user_manager],
  delete: [:admin, :user_manager]

  def configure(c)
    super

    c.title ||= I18n.t('users', default: "Users")
    c.model                  = "Marty::User"
    c.enable_extended_search = false
    c.enable_edit_inline     = false
    c.multi_select           = false

    c.columns ||=
      [
       :login,
       :firstname,
       :lastname,
       :active,
       :uuid,
       :roles
      ]

    c.data_store.sorters = {
      property: :login,
      direction: 'ASC',
    } if c.columns.include?(:login)
  end

  def self.set_roles(roles, user)
    roles ||= []

    # Destroy old roles (must call destroy for auditing to work properly)
    user.user_roles.each do |ur|
      ur.destroy unless roles.include?(I18n.t("roles.#{ur.role.name}"))
    end

    # set new roles
    user.roles = Marty::Role.select {
      |r| roles.include? I18n.t("roles.#{r.name}")
    }
  end

  def self.create_edit_user(data)
    # Creates the initial place-holder user object and check it
    # out.
    user = data["id"].nil? ? Marty::User.new : Marty::User.find(data["id"])
    user.login     = data["login"]
    user.firstname = data["firstname"]
    user.lastname  = data["lastname"]
    user.active    = data["active"]
    user.uuid      = data["uuid"]

    if user.valid?
      user.save
      set_roles(data["roles"], user)
    end

    user
  end

  # override the add_in_form and edit_in_form endpoint. User creation/update
  # needs to use the create_edit_user method.

  endpoint :add_window__add_form__netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    data["id"] = nil

    unless self.class.can_perform_action?(:create)
      this.netzke_feedback "Permission Denied"
      return
    end

    user = self.class.create_edit_user(data)
    if user.valid?
      this.success = true
      this.on_submit_success
    else
      data_adapter.errors_array(user).each do |error|
        flash :error => error
      end
      this.netzke_feedback(@flash)
    end
  end

  endpoint :edit_window__edit_form__netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])
    unless self.class.can_perform_action?(:update)
      this.netzke_feedback "Permission Denied"
      return
    end

    user = self.class.create_edit_user(data)
    if user.valid?
      this.success = true
      this.on_submit_success
    else
      data_adapter.errors_array(user).each do |error|
        flash :error => error
      end
      this.netzke_feedback(@flash)
    end
  end

  action :add_in_form do |a|
    a.text     = I18n.t("user_grid.new")
    a.tooltip  = I18n.t("user_grid.new")
    a.icon     = :user_add
    a.disabled = !self.class.can_perform_action?(:create)
  end

  action :edit_in_form do |a|
    a.disabled = !self.class.can_perform_action?(:update)
    a.icon     = :user_edit
  end

  action :del do |a|
    a.icon     = :user_delete
  end

  def default_bbar
    [:add_in_form, :edit_in_form, :del]
  end

  def default_context_menu
    []
  end

  column :login do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.login")
  end

  column :firstname do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.firstname")
  end

  column :lastname do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.lastname")
  end

  column :active do |c|
    c.width = 60
    c.text  = I18n.t("user_grid.active")
  end

  column :uuid do |c|
    c.width = 60
    c.text  = I18n.t("user_grid.uuid")
  end

  column :roles do |c|
    c.width  = 100
    c.flex   = 1
    c.editor = {
      trigger_action: :all,
      name: "roles",
      attr_type: :string,
      xtype: :combo,
      store: Marty::Role.pluck(:name).map {|n| I18n.t("roles.#{n}")}.sort,
      empty_text: "Roles",
      multi_select: true,
    }

    c.getter = lambda do |r|
      r.roles.map { |ur| I18n.t("roles.#{ur.name}") }.sort
    end
  end

  column :created_dt do |c|
    c.text      = I18n.t("user_grid.created_dt")
    c.format    = "Y-m-d H:i"
    c.read_only = true
  end

end

UserView = Marty::UserView
