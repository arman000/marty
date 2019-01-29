module Marty; class UserView < Marty::Grid
  has_marty_permissions create: [:admin, :user_manager],
                        read:   :any,
                        update: [:admin, :user_manager],
                        delete: [:admin, :user_manager]

  # list of columns to be displayed in the grid view
  def self.user_columns
    [
      :login,
      :firstname,
      :lastname,
      :active,
      :roles,
    ]
  end

  def configure(c)
    super

    c.attributes   ||= self.class.user_columns
    c.title        ||= I18n.t('users', default: "Users")
    c.model          = "Marty::User"
    c.editing        = :in_form
    c.paging         = :pagination
    c.multi_select   = false
    c.store_config.merge!(sorters: [{ property: :login,
                                     direction: 'ASC',
                                    }]) if c.attributes.include?(:login)
    c.scope = ->(arel) { arel.includes(:roles) }
  end

  def self.set_roles(roles, user)
    roles ||= []

    # Destroy old roles (must call destroy for auditing to work properly)
    user.user_roles.each do |ur|
      ur.destroy unless roles.include?(I18n.t("roles.#{ur.role.name}"))
    end

    # set new roles
    user.roles = Role.select { |r|
                   roles.include? I18n.t("roles.#{r.name}")
    }
  end

  def self.create_edit_user(data)
    # Creates initial place-holder user object and validate
    user = data["id"].nil? ? User.new : User.find(data["id"])

    user_columns.each do |c|
      user.send("#{c}=", data[c.to_s]) unless c == :roles
    end

    if user.valid?
      user.save
      set_roles(data["roles"], user)
    end

    user
  end

  # override the add_in_form and edit_in_form endpoint. User creation/update
  # needs to use the create_edit_user method.

  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    data["id"] = nil

    unless self.class.can_perform_action?(:create)
      client.netzke_notify "Permission Denied"
      return
    end

    user = self.class.create_edit_user(data)
    if user.valid?
      client.success = true
      client.netzke_on_submit_success
    else
      client.netzke_notify(model_adapter.errors_array(user).join("\n"))
    end
  end

  endpoint :edit_window__edit_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])
    unless self.class.can_perform_action?(:update)
      client.netzke_notify "Permission Denied"
      return
    end

    user = self.class.create_edit_user(data)
    if user.valid?
      client.success = true
      client.netzke_on_submit_success
    else
      client.netzke_notify(model_adapter.errors_array(user).join("\n"))
    end
  end

  action :add do |a|
    super(a)
    a.text     = I18n.t("user_grid.new")
    a.tooltip  = I18n.t("user_grid.new")
    a.icon_cls = "fa fa-user-plus glyph"
  end

  action :edit do |a|
    super(a)
    a.icon_cls = "fa fa-user-cog glyph"
  end

  action :delete do |a|
    super(a)
    a.icon_cls = "fa fa-user-minus glyph"
  end

  def default_context_menu
    []
  end

  attribute :login do |c|
    c.width   = 100
    c.label   = I18n.t("user_grid.login")
  end

  attribute :firstname do |c|
    c.width   = 100
    c.label   = I18n.t("user_grid.firstname")
  end

  attribute :lastname do |c|
    c.width   = 100
    c.label   = I18n.t("user_grid.lastname")
  end

  attribute :active do |c|
    c.width   = 60
    c.label   = I18n.t("user_grid.active")
  end

  attribute :roles do |c|
    c.width   = 100
    c.flex    = 1
    c.label   = I18n.t("user_grid.roles")
    c.type    = :string,

                c.getter = lambda do |r|
                  r.roles.map { |ur| I18n.t("roles.#{ur.name}") }.sort
                end

    c.editor_config = {
      multi_select: true,
      empty_text:   I18n.t("user_grid.select_roles"),
      store:        Role.pluck(:name).map { |n| I18n.t("roles.#{n}") }.sort,
      type:         :string,
      xtype:        :combo,
    }
  end

  attribute :created_dt do |c|
    c.label     = I18n.t("user_grid.created_dt")
    c.format    = "Y-m-d H:i"
    c.read_only = true
  end
end; end

UserView = Marty::UserView
