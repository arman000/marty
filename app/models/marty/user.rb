class Marty::User < Marty::Base
  validates_presence_of :login, :firstname, :lastname
  validates_uniqueness_of :login

  validates_format_of :login, :with => /\A[a-z0-9_\-@\.]*\z/i
  validates_length_of :login, :firstname, :lastname, maximum: 100

  MARTY_IMPORT_UNIQUENESS = [:login]

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  scope :active, -> { where(active: true) }

  validate :verify_changes
  before_destroy :destroy_user

  def name
    "#{firstname} #{lastname}"
  end

  def to_s
    name
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

    user = find_by_login(login)

    return nil if !user || !user.active?

    authenticate_with?(login, password) || nil
  end

  def self.authenticate_with?(login, password)
    cf = Rails.configuration.marty

    auth_source = cf.auth_source.to_s

    if auth_source == "local"
      ok = password == cf.local_password
    elsif auth_source == "ldap"
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
                             username: cf.domain + "\\" + login,
                             password: password,
                           })
      ok = ldap.bind
    else
      raise "bad auth_source: #{auth_source.inspect}"
    end

    find_by_login(login) if ok
  end

  def self.current=(user)
    Mcfly.whodunnit = user
  end

  def self.current
    Mcfly.whodunnit
  end

 def self.has_role(role)
    mr = Mcfly.whodunnit.roles rescue []
    mr.any? {|attr| attr.name == role}
 end

private
  def verify_changes
    # If current users role is only user_manager, restrict following
    # 1 - Do not allow user to edit own record
    # 2 - Do not allow user to edit the application system record
    if user_manager_only
      system_user = Marty::User.find_by_login(
        Rails.configuration.marty.system_account.to_s)
      system_id = system_user.id if system_user

      if self.id == Mcfly.whodunnit.id
        roles.each {|r| roles.delete r unless r.name == "user_manager"}
        errors.add :base, "User Managers cannot edit "\
          "or add additional roles to their own accounts"
      elsif self.id == system_id
        errors.add :base,
        "User Managers cannot edit the application system account"
      end
    end

    errors.add :base, "The application system account cannot be deactivated" if
      self.login == Rails.configuration.marty.system_account.to_s &&
      !self.active

    errors.blank?
  end

  def user_manager_only
    Marty::User.has_role("user_manager") && !Marty::User.has_role("admin")
  end

  def destroy_user
    errors.add :base, "You cannot delete your own account" if
      self.login == Mcfly.whodunnit.login

    errors.add :base, "You cannot delete the system account" if
      self.login == Rails.configuration.marty.system_account.to_s
    # Default to disallowing any deletions for now

    errors.add :base,
    "Users cannot be deleted - set 'Active' to false to disable the account"

    throw :abort unless errors.blank?
  end
end
