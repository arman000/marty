class Marty::Aws::CognitoView < Marty::Aws::Grid
  aws_model('cognito', 'user')

  ATTRIBUTES = {
    username:                {type: :string},
    api_key:                 {type: :string},
    enabled:                 {type: :boolean},
    user_status:             {type: :string},
    user_create_date:        {type: :datetime, label: 'User Create Date'},
    user_last_modified_date: {type: :datetime, label: 'User Last Modified Date'},
    mfa_options:             {type: :string,   label: 'MFA Options'},
  }

  NESTED_ATTRIBUTES = {
    email:          {type: :string},
    email_verified: {type: :string, label: 'Email Verification Status'},
  }

  ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value)
  end

  NESTED_ATTRIBUTES.each do |a, h|
    field_maker(a.to_s, h, :value, ['attributes'])
  end

  def configure(c)
    super
    c.title      = "AWS Cognito Users"
    c.attributes = ATTRIBUTES.keys + NESTED_ATTRIBUTES.keys
  end

  client_class do |c|
    c.netzke_on_do_toggle_user_access = l(<<-JS)
    function(params) {
      this.server.toggleUserAccess();
    }
    JS

    c.netzke_on_do_reset_user_password = l(<<-JS)
    function(params) {
      this.server.resetUserPassword();
    }
    JS
  end

  action :do_toggle_user_access do |a|
    a.text     = 'Toggle Access'
    a.icon_cls = "fa fa-wrench glyph"
    a.disabled = true
  end

  action :do_reset_user_password do |a|
    a.text     = 'Reset Password'
    a.icon_cls = "fa fa-key glyph"
    a.disabled = true
  end


  endpoint :toggle_user_access do
    aws_async_wait :reload do
      record   = Marty::Aws::Object.find(client_config['selected'])
      username = record.value['username']
      cog      = Marty::Aws::Cognito.new
      if record.value['enabled']
        cog.admin_disable_user(username)
      else
        cog.admin_enable_user(username)
      end
    end
  end

  endpoint :reset_user_password do
    aws_async_wait :reload do
      username = Marty::Aws::Object.find(client_config['selected']).
                   value['username']

      Marty::Aws::Cognito.new.admin_reset_password(username)
    end
  end

  def join_api_key r
    v = r.value
    username = v['username']
    email    = v['attributes'].select{|h| h['name'] == 'email'}.first['value']
    api_key  = Marty::Aws::ApiKey.where(username: username, email: email).first
    r.value['api_key'] = api_key.try(:value)
    r.save!
  end

  def get_records params
    super.each{|r| join_api_key(r)}
  end

  def default_bbar
    [:do_toggle_user_access, :do_reset_user_password]
  end
end

AwsCognitoView = Marty::Aws::CognitoView
