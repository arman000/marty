class Marty::User < Marty::Base
  validates :login, :firstname, :lastname, presence: true
  validates :login, uniqueness: true

  validates :login, format: { with: /\A[a-z0-9_\-@\.]*\z/i }
  validates :login, :firstname, :lastname, length: { maximum: 100 }

  MARTY_IMPORT_UNIQUENESS = [:login]

  has_many :user_roles, dependent: :destroy

  has_many(
    :notification_deliveries,
    class_name: '::Marty::Notifications::Delivery',
    dependent: :destroy,
    foreign_key: :recipient_id,
    inverse_of: :recipient
  )

  scope :active, -> { where(active: true) }

  validate :verify_changes
  before_destroy :destroy_user

  def name
    "#{firstname} #{lastname}"
  end

  def to_s
    name
  end

  def roles
    user_roles.map(&:role)
  end

  # Returns the user who matches the given autologin +key+ or nil
  def self.try_to_autologin(key)
    tokens = Marty::Token.find_all_by_action_and_value('autologin', key.to_s)
    # Make sure there's only 1 token that matches the key
    if tokens.size == 1
      token = tokens.first
      autologin = Rails.configuration.marty.autologin || 0

      if (token.created_on > autologin.to_i.day.ago) &&
          token.user && token.user.active?
        token.user
      end
    end
  end

  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password)
    login = login.to_s
    password = password.to_s

    # Make sure no one can sign in with an empty password
    return nil if password.empty?

    user = find_by(login: login)

    return nil if !user || !user.active?

    authenticate_with?(login, password) || nil
  end

  def self.ldap_login(login, password)
    # IMPORTANT NOTE: if server allows anonymous LDAP access, empty
    # passwords will succeed!  i.e. if a valid user with empty
    # password is sent in, ldap.bind will return OK.
    cf = Rails.configuration.marty.ldap
    ldap = Net::LDAP.new(host: cf.host,
                         port: cf.port,
                         base: cf.base_dn,
                         encryption: cf.encryption,
                         auth: {
                           method: :simple,
                           username: cf.domain + '\\' + login,
                           password: password,
                         })
    ldap.bind
  end

  def self.authenticate_with?(login, password)
    cf = Rails.configuration.marty

    auth_source = cf.auth_source.to_s

    if auth_source == 'local'
      ok = password == cf.local_password
    elsif auth_source == 'ldap'
      ok = ldap_login(login, password)
    else
      raise "bad auth_source: #{auth_source.inspect}"
    end

    find_by(login: login) if ok
  end

  def self.current=(user)
    Mcfly.whodunnit = user
  end

  def self.current
    Mcfly.whodunnit
  end

  def self.has_role(role)
     mr = Mcfly.whodunnit.user_roles rescue []
     mr.any? { |ur| ur.role == role }
  end

  delorean_fn :export_for_report do
     Marty::User.includes(:user_roles).map do |user|
       {
         'login' => user.login,
         'firstname' => user.firstname,
         'lastname' => user.lastname,
         'active' => user.active,
         'roles' => user.roles.sort.join(', ')
       }
     end
  end

  def unread_web_notifications_count
    notification_deliveries.where(
      delivery_type: :web,
      state: [:sent]
    ).count
  end

  private

  def verify_changes
    # If current users role is only user_manager, restrict following
    # 1 - Do not allow user to edit own record
    # 2 - Do not allow user to edit the application system record
    if user_manager_only
      system_user = Marty::User.find_by(
        login: Rails.configuration.marty.system_account.to_s)
      system_id = system_user.id if system_user

      roles = user_roles.map(&:role)

      if id == Mcfly.whodunnit.id
        roles.each { |r| roles.delete r unless r == 'user_manager' }
        errors.add :base, 'User Managers cannot edit '\
          'or add additional roles to their own accounts'
      elsif id == system_id
        errors.add :base,
                   'User Managers cannot edit the application system account'
      end
    end

    errors.add :base, 'The application system account cannot be deactivated' if
      login == Rails.configuration.marty.system_account.to_s &&
      !active

    errors.blank?
  end

  def user_manager_only
    Marty::User.has_role('user_manager') && !Marty::User.has_role('admin')
  end

  def destroy_user
    errors.add :base, 'You cannot delete your own account' if
      login == Mcfly.whodunnit.login

    errors.add :base, 'You cannot delete the system account' if
      login == Rails.configuration.marty.system_account.to_s
    # Default to disallowing any deletions for now

    errors.add :base,
               "Users cannot be deleted - set 'Active' to false to disable the account"

    throw :abort if errors.present?
  end
end
