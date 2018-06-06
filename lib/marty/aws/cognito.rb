require 'aws-sdk-cognitoidentityprovider'

class Marty::Aws::Cognito
  attr_accessor :client, :id

  def initialize
    aws_base = Marty::Aws::Base.new
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: aws_base.doc[:region],
      access_key_id: aws_base.creds[:access_key_id],
      secret_access_key: aws_base.creds[:secret_access_key],
      session_token: aws_base.creds[:token]
    )
    @id     = Marty::Config['AWS_COGNITO_CLIENT_ID']
    @secret = get_user_pool_client_secret
  end

  def secret_hash msg
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha256'),
        @secret, msg + @id
      )
    ).strip
  end

  def sign_up invite_token, email, username, password
    client.sign_up(
      client_id: @id,
      password: password,
      secret_hash: secret_hash(username),
      user_attributes: [
        {
          name: 'email',
          value: email,
        },
      ],
      username: username,
    )
  end

  def resend_confirmation_code username
    client.resend_confirmation_code(
      client_id: @id,
      secret_hash: secret_hash(username),
      username: username,
    )
  end

  def confirm_sign_up username, confirmation_code
    client.confirm_sign_up(
      client_id: @id,
      confirmation_code: confirmation_code,
      force_alias_creation: false,
      secret_hash: secret_hash(username),
      username: username,
    )
  end

  def admin_initiate_auth username, password
    client.admin_initiate_auth(
      auth_flow: "ADMIN_NO_SRP_AUTH",
      auth_parameters: {
        'USERNAME' => username,
        'PASSWORD' => password,
        'SECRET_HASH' => secret_hash(username),
      },
      client_id: @id,
      user_pool_id: user_pool.id,
    )
  end

  def admin_refresh_token username, refresh_token
    client.admin_initiate_auth(
      auth_flow: "REFRESH_TOKEN_AUTH",
      auth_parameters: {
        'REFRESH_TOKEN' => refresh_token,
        'SECRET_HASH'   => secret_hash(username),
      },
      client_id: @id,
      user_pool_id: user_pool.id,
    )
  end

  def forgot_password username
    client.forgot_password(
      client_id: @id,
      secret_hash: secret_hash(username),
      username: username,
    )
  end

  def confirm_forgot_password username, password, confirmation_code
    client.confirm_forgot_password(
      client_id: @id,
      secret_hash: secret_hash(username),
      username: username,
      confirmation_code: confirmation_code,
      password: password,
    )
  end

  def identity_providers
    client.list_identity_providers(
      user_pool_id: user_pool.id,
      max_results: 60,
    ).try(:providers)
  end

  def admin_user_method method, username
    opts = {user_pool_id: user_pool.id, username: username}
    client.send(method, opts)
  end

  def admin_reset_password username
    admin_user_method(:admin_reset_user_password, username)
  end

  def admin_disable_user username
    admin_user_method(:admin_disable_user, username)
  end

  def admin_enable_user username
    admin_user_method(:admin_enable_user, username)
  end

  def admin_delete_user username
    admin_user_method(:admin_delete_user, username)
  end

  def user_pool
    get_user_pool_by_name('gemini-external-api')
  end

  def user_pools
    resp = client.list_user_pools({max_results: 60})
    resp.try(:user_pools) || []
  end

  def get_user_pool_by_name name
    @@up_cache       ||= {}
    @@up_cache[name] ||= user_pools.select{|up| up.name == name}.uniq.first
  end

  def get_user_pool_client_secret
    resp = client.describe_user_pool_client(
      user_pool_id: user_pool.id,
      client_id: @id,
    ).try(:user_pool_client).try(:client_secret)
  end

  def get_users id=nil
    return [] unless id
    begin
      resp = client.list_users(
        user_pool_id: id,
        limit: 50,
      )

      resp.try(:users)
    end
  end
end
