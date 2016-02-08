class Marty::UserView < Marty::Grid
  has_marty_permissions \
  create: [:admin, :user_manager],
  read: :any,
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

    c.title ||= I18n.t('users', default: "Users")
    c.model                  = "Marty::User"
    c.editing                = :in_form
    c.paging                 = :pagination
    c.multi_select           = false
    c.attributes ||= self.class.user_columns
    c.store_config.merge!({sorters: [{property: :login,
                                 direction: 'ASC',
                                }]}) if c.attributes.include?(:login)
    c.scope = ->(arel) { arel.includes(:roles) }
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
    # Creates initial place-holder user object and validate
    user = data["id"].nil? ? Marty::User.new : Marty::User.find(data["id"])

    self.user_columns.each {
      |c| user.send("#{c}=", data[c.to_s]) unless c == :roles
    }

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
      model_adapter.errors_array(user).each do |error|
        flash :error => error
      end
      client.netzke_notify(@flash)
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
      model_adapter.errors_array(user).each do |error|
        flash :error => error
      end
      client.netzke_notify(@flash)
    end
  end

  action :add do |a|
    super(a)
    a.text     = I18n.t("user_grid.new")
    a.tooltip  = I18n.t("user_grid.new")
    a.icon     = :user_add
  end

  action :edit do |a|
    super(a)
    a.icon     = :user_edit
  end

  action :delete do |a|
    super(a)
    a.icon     = :user_delete
  end

  def default_context_menu
    []
  end

  attribute :login do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.login").upcase
  end

  attribute :firstname do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.firstname")
  end

  attribute :lastname do |c|
    c.width = 100
    c.text  = I18n.t("user_grid.lastname")
  end

  attribute :active do |c|
    c.width = 60
    c.text  = I18n.t("user_grid.active")
  end

  attribute :roles do |c|
    c.width  = 100
    c.flex   = 1
    c.text   = I18n.t("user_grid.roles")
    c.type   = :string,

    c.getter = lambda do |r|
      r.roles.map { |ur| I18n.t("roles.#{ur.name}") }.sort
    end
  end

  attribute :created_dt do |c|
    c.text      = I18n.t("user_grid.created_dt")
    c.format    = "Y-m-d H:i"
    c.read_only = true
  end

  def default_form_items
    [
      :login,
      :firstname,
      :lastname,
      :active,
      { name: :uuid,
        text: I18n.t("uuid")
      },
      {
        name: "roles",
        xtype: :combo,
        type: :string,
        store: Marty::Role.pluck(:name).map {|n| I18n.t("roles.#{n}")}.sort,
        empty_text: I18n.t("user_grid.select_roles"),
        multi_select: true,
        getter: lambda do |r|
          r.roles.map { |ur| I18n.t("roles.#{ur.name}") }.sort
        end
      }
    ]
  end
end

UserView = Marty::UserView
