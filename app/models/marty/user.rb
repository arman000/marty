require 'mcfly'
require 'net/ldap'

class Marty::User < Marty::Base
  attr_protected :login, :firstname, :lastname, :active

  validates_presence_of :login, :firstname, :lastname
  validates_uniqueness_of :login

  validates_format_of :login, :with => /^[a-z0-9_\-@\.]*$/i
  validates_length_of :login, :firstname, :lastname, maximum: 100

  has_many :user_roles
  has_many :roles, through: :user_roles

  scope :active, :conditions => "#{self.table_name}.active = true"

  # FIXME: should have before_destroy

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

    user.authenticate_with?(login, password) || nil
  end

  def self.authenticate_with?(login, password)
    cf = Rails.configuration.marty

    auth_source = cf.auth_source.to_s

    if auth_source == "local"
      ok = password == cf.local_password
    elsif auth_source == "ldap"
      cf = Rails.configuration.marty.ldap
      ldap = Net::LDAP.new(host: cf.host,
                           port: cf.port,
                           base: cf.base_dn,
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

end
