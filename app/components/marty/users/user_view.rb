module Marty
  module Users
    class UserView < Marty::Grid
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
          :user_roles,
        ]
      end

      def configure(c)
        super

        c.attributes   ||= self.class.user_columns
        c.title        ||= I18n.t('users', default: 'Users')
        c.model          = 'Marty::User'
        c.editing        = :in_form
        c.paging         = :pagination
        c.multi_select   = false
        if c.attributes.include?(:login)
          c.store_config[:sorters] = [{ property: :login,
                                           direction: 'ASC', }]
        end
        c.scope = ->(arel) { arel.includes(:user_roles) }
      end

      def self.set_roles(roles, user)
        roles = [] if roles.blank?

        roles = ::Marty::UserRole.from_nice_names(roles)

        roles_in_user = user.user_roles.map(&:role)
        roles_to_delete = roles_in_user - roles
        roles_to_add = roles - roles_in_user

        Marty::User.transaction do
          user.user_roles.where(role: roles_to_delete).map(&:destroy!)

          roles_to_add.each do |role|
            user.user_roles.create!(role: role)
          end
        end
      end

      def self.create_edit_user(data)
        # Creates initial place-holder user object and validate
        user = data['id'].nil? ? User.new : User.find(data['id'])

        user_columns.each do |c|
          user.send("#{c}=", data[c.to_s]) unless c == :user_roles
        end

        if user.valid?
          user.save
          set_roles(data['user_roles'], user)
        end

        user
      end

      # override the add_in_form and edit_in_form endpoint. User creation/update
      # needs to use the create_edit_user method.

      endpoint :add_window__add_form__submit do |params|
        data = ActiveSupport::JSON.decode(params[:data])

        data['id'] = nil

        unless self.class.can_perform_action?(:create)
          client.netzke_notify 'Permission Denied'
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
          client.netzke_notify 'Permission Denied'
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
        a.text     = I18n.t('user_grid.new')
        a.tooltip  = I18n.t('user_grid.new')
        a.icon_cls = 'fa fa-user-plus glyph'
      end

      action :edit do |a|
        super(a)
        a.icon_cls = 'fa fa-user-cog glyph'
      end

      action :delete do |a|
        super(a)
        a.icon_cls = 'fa fa-user-minus glyph'
      end

      def default_context_menu
        []
      end

      attribute :login do |c|
        c.width   = 100
        c.label   = I18n.t('user_grid.login')
      end

      attribute :firstname do |c|
        c.width   = 100
        c.label   = I18n.t('user_grid.firstname')
      end

      attribute :lastname do |c|
        c.width   = 100
        c.label   = I18n.t('user_grid.lastname')
      end

      attribute :active do |c|
        c.width   = 60
        c.label   = I18n.t('user_grid.active')
      end

      attribute :user_roles do |c|
        c.width   = 100
        c.flex    = 1
        c.label   = I18n.t('user_grid.roles')
        c.type    = :string

        c.getter = lambda do |r|
          Marty::UserRole.to_nice_names(r.user_roles.map(&:role))
        end

        roles = ::Marty::UserRole.role_values
        store = ::Marty::UserRole.to_nice_names(roles.sort)

        c.editor_config = {
          multi_select: true,
          empty_text:   I18n.t('user_grid.select_roles'),
          store:        store,
          type:         :string,
          xtype:        :combo,
        }
      end

      attribute :created_dt do |c|
        c.label     = I18n.t('user_grid.created_dt')
        c.format    = 'Y-m-d H:i'
        c.read_only = true
      end
    end
  end
end
