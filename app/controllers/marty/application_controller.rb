class Marty::ApplicationController < ActionController::Base
  layout 'marty/application'

  protect_from_forgery

  # Marty's ApplicationController is based on Redmine's
  # implementation.

  def handle_unverified_request
    super
    cookies.delete(:autologin)
  end

  before_action :session_expiration,
                :user_setup

  def get_conf
    Rails.configuration.marty
  end

  def session_expiration
    if session[:user_id]
      if session_expired? && !try_to_autologin
        reset_session
        reset_signed_cookies
      else
        session[:atime] = Time.now.utc.to_i
      end
    end
  end

  def session_expired?
    session_lifetime, session_timeout =
      get_conf.session_lifetime, get_conf.session_timeout

    if session_lifetime
      return true unless session[:ctime] &&
        (Time.now.utc.to_i -
         session[:ctime].to_i <= session_lifetime.to_i * 60)
    end

    if session_timeout
      return true unless session[:atime] &&
        (Time.now.utc.to_i - session[:atime].to_i <= session_timeout.to_i * 60)
    end

    false
  end

  def start_user_session(user)
    session[:user_id] = user.id
    session[:ctime] = Time.now.utc.to_i
    session[:atime] = Time.now.utc.to_i

    set_signed_cookies
  end

  def user_setup
    # Find the current user
    user = Marty::User.current = find_current_user

    logger.info("  Current user: #{user.login} (id=#{user.id})") if
      logger && user
  end

  # Returns the current user or nil if no user is logged in
  def find_current_user
    user_id = session[:user_id]
    if user_id
      user = Marty::User.active.find(user_id) rescue nil
    else
      user = try_to_autologin
    end

    user
  end

  def try_to_autologin
    if cookies[:autologin] && get_conf.autologin
      # auto-login feature starts a new session
      user = Marty::User.try_to_autologin(cookies[:autologin])
      if user
        reset_session
        reset_signed_cookies
        start_user_session(user)
      end
      user
    end
  end

  # Sets the logged in user
  def set_user(user)
    reset_session
    reset_signed_cookies
    if user && user.is_a?(Marty::User)
      Marty::User.current = user
      start_user_session(user)
    else
      Marty::User.current = nil
    end
  end

  # Logs out current user
  def logout_user
    if Marty::User.current
      cookies.delete :autologin
      Marty::Token.where(user_id: Marty::User.current.id).delete_all unless
        Marty::Util.db_in_recovery?
      set_user(nil)
    end
  end

  def password_authentication
    user = Marty::User.try_to_login(params[:username], params[:password])

    user.nil? ? failed_authentication(params[:username] || 'nil username') :
      successful_authentication(user)
  end

  def failed_authentication(login)
    logger.info("Failed authentication for '#{login}' " +
                "from #{request.remote_ip} at #{Time.now.utc}")
  end

  def successful_authentication(user)
    logger.info("Successful authentication for '#{user.login}' " +
                "from #{request.remote_ip} at #{Time.now.utc}")
    set_user(user)
  end

  def set_signed_cookies
    cookies.signed[:user_id] = session[:user_id]
  end

  def reset_signed_cookies
    cookies.signed[:user_id] = nil
  end

  def toggle_dark_mode
    cookies[:dark_mode] = cookies[:dark_mode] != 'true'
  end
end
