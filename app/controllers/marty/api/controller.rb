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

  ### parameters ###

  def oauth_params
    params.permit!
  end

  def user_sign_in_params
    params.require(:user).permit!
  end

  def user_sign_up_params
    params.require(:user).permit(:invite_token, :email, :username, :password)
  end

  def user_confirm_sign_up_params
    params.require(:user).permit(:username, :confirmation_code)
  end

  def user_forgot_password_params
    params.require(:user).permit(:username)
  end

  def user_confirm_forgot_password_params
    params.require(:user).permit(:username, :password, :confirmation_code)
  end

  ### actions ###

  def index
    @path     = (params[:path] || 'sign_in')
    @username = params[:username]
  end

  def sign_in
    params = user_sign_in_params
    begin
      resp = Client.new.admin_initiate_auth(params[:username], params[:password])
    rescue => e
      flash[:danger] = "Incorrect username or password."
    else
      flash[:success] = 'Authentication Successful'
    end
    redirect_to url_for(:api)
  end

  def validate_and_register_invite_token token, username, email
    key = Marty::AwsApiKey.where(value: token, username: nil, email: nil).first
    raise 'Invalid invite token' unless key

    key.username = username
    key.email    = email
    key.save!
  end

  def sign_up
    params = user_sign_up_params
    reload_on_raise do
      validate_and_register_invite_token(params[:invite_token],
                                         params[:username],
                                         params[:email])

      Client.new.sign_up(params[:invite_token],
                         params[:email],
                         params[:username],
                         params[:password])
      flash[:success] = 'Sign up successful! Please confirm user account.'
      redirect_to url_for(:api) + '?path=confirm_sign_up&username=' +
                  params[:username]
    end
  end

  def confirm_sign_up
    params = user_confirm_sign_up_params

    reload_on_raise do
      Client.new.confirm_sign_up(params[:username],
                                 params[:confirmation_code])
      flash[:success] = "Account confirmed."
      redirect_to url_for(:api)
    end
  end

  def forgot_password
    params = user_forgot_password_params
    reload_on_raise do
      Client.new.forgot_password(params[:username])

      flash[:success] = "Create a new paoauthd."
      redirect_to url_for(:api) + '?path=confirm_forgot_password&username=' +
                  params[:username]
    end
  end

  def confirm_forgot_password
    params = user_confirm_forgot_password_params
    reload_on_raise do
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
      api_key   = oauth_params['api-key']
      username  = params[:username]
      local_key = Marty::AwsApiKey.where(value: api_key).first

      result = {'error' => 'invalid api key association'} unless
        local_key.username == username

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
      Marty::Logger.log('error', 'aws_api_error', e.message)
      result = {'error' => 'invalid request'}
    end

    respond_to do |format|
      format.json {render json: result.as_json.except('new_device_metadata')}
    end
  end
end
