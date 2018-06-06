class Marty::Api::Controller < ActionController::Base
  Client = Marty::Aws::Cognito

  def if_confirmation?
    params[:user] && params[:user][:confirmation_code]
  end

  def get_user
    params[:user] && params[:user][:username]
  end

  def reload_on_raise error_mask = nil
    begin
      yield
    rescue => e
      flash[:danger] = error_mask || e.message
      redirect_to url_for(:api) + '?path=' + caller_locations(2,2)[0].label +
                  (if_confirmation? ? '&username=' + get_user : '')
    end
  end

  def oauth_params
    params.permit!
  end

  def user_sign_in_params
    params.require(:user).permit!
  end

  def user_sign_up_params
    params.require(:user).permit(
      :api_key,
      :email,
      :username,
      :password,
      :password_confirmation
    )
  end

  def user_forgot_password_params
    params.require(:user).permit(:api_key, :username)
  end

  def user_confirm_forgot_password_params
    params.require(:user).permit(
      :username,
      :password,
      :password_confirmation,
      :confirmation_code
    )
  end

  def index
    @path     = (params[:path] || 'sign_in')
    @username = params[:username]
  end

  def sign_in
    params = user_sign_in_params

    if params[:password] == params[:password_confirmation]
      begin
        resp = Client.new.admin_initiate_auth(params[:username], params[:password])
      rescue => e
        flash[:danger] = "Incorrect username or password."
      else
        flash[:success] = 'Authentication Successful'
      end
    else
      flash[:danger] = "Passwords must match"
    end

    redirect_to url_for(:api)
  end

  def sign_up
    params = user_sign_up_params

    reload_on_raise do
      raise 'Passwords must match' unless
        params[:password] == params[:password_confirmation]

      api_auth = Marty::ApiAuth.where(api_key: params[:api_key]).first

      raise 'Invalid invite token' unless api_auth

      key = api_auth.parameters['aws_api_key']

      raise 'Token has expired' unless key &&
                                       key['username'].nil? &&
                                       key['email'].nil?

      Client.new.sign_up(params[:api_key],
                         params[:email],
                         params[:username],
                         params[:password])

      Mcfly.whodunnit = Marty::User.find_by_login(
        Rails.configuration.marty.system_account.to_s)

      begin
        api_auth.parameters['aws_api_key'] += {
          'username' => params[:username],
          'email'    => params[:email],
        }

        api_auth.save!
      rescue => e
        Marty::Logger.log('api_controller', 'sign_up', e.message)
        raise 'Internal server error'
      end

      flash[:success] = 'Sign up successful! Please check your email.'
      redirect_to url_for(:api)
    end
  end

  def forgot_password
    params = user_forgot_password_params

    reload_on_raise do

      api_auth = Marty::ApiAuth.where(api_key: params[:api_key]).first
      raise 'Permission denied' unless api_auth

      Client.new.forgot_password(params[:username])

      flash[:success] = "Create a new password."
      redirect_to url_for(:api) + '?path=confirm_forgot_password&username=' +
                  params[:username]
    end
  end

  def confirm_forgot_password
    params = user_confirm_forgot_password_params

    reload_on_raise do
      raise 'Passwords must match' unless
        params[:password] == params[:password_confirmation]

      Client.new.confirm_forgot_password(params[:username],
                                         params[:password],
                                         params[:confirmation_code])

      flash[:success] = "Password change successful."
      redirect_to url_for(:api)
    end
  end

  def token
    request_params = oauth_params
    params = oauth_params[:body]

    result = {'error' => 'invalid_grant'} unless
      ['password', 'refresh_token'].include?(params[:grant_type])

    begin
      api_key   = oauth_params['api_key']
      username  = params[:username]
      api_auth = Marty::ApiAuth.where(api_key: api_key).first

      result = {'error' => 'invalid api key association'} unless
        api_auth.try(:aws_api_key).try(:username) == username

      if !result
        c = Client.new
        result = case params[:grant_type]
                 when 'password'
                   c.admin_initiate_auth(username, params[:password]).
                     try(:authentication_result)
                 when 'refresh_token'
                   c.admin_refresh_token(username, params[:refresh_token]).
                     try(:authentication_result)
                 end
      end
    rescue => e
      Marty::Logger.log('api_controller', 'token_request', e.message)
      result = {'error' => 'invalid request'}
    end

    respond_to do |format|
      format.json {render json: result.as_json.except('new_device_metadata')}
    end
  end
end
