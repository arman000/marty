class Marty::AwsCognitoView < Marty::AwsGrid
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
    c.toggle_user_access = l(<<-JS)
    function(params) {
      var selection = this.ownerGrid.getSelectionModel().getSelection()[0];
      this.server.toggleUserAccess(selection.id);
    }
    JS

    c.delete_user = l(<<-JS)
    function(params) {
      var selection = this.ownerGrid.getSelectionModel().getSelection()[0];
      this.server.deleteUser(selection.id);
    }
    JS

    c.reset_user_password = l(<<-JS)
    function(params) {
      var selection = this.ownerGrid.getSelectionModel().getSelection()[0];
      this.server.resetUserPassword(selection.id);
    }
    JS
  end

  action :toggle_user_access do |a|
    a.text     = 'Toggle Access'
    a.handler  = :toggle_user_access
    a.icon     = :wrench
  end

  action :reset_user_password do |a|
    a.text     = 'Reset Password'
    a.handler  = :reset_user_password
    a.icon     = :key
  end

  action :delete_user do |a|
    a.text     = 'Delete'
    a.handler  = :delete_user
    a.icon     = :delete
  end

  endpoint :toggle_user_access do |id|
    aws_async_wait :reload do
      record   = Marty::AwsObject.find(id)
      username = record.value['username']
      cog      = Marty::Aws::Cognito.new
      if record.value['enabled']
        cog.admin_disable_user(username)
      else
        cog.admin_enable_user(username)
      end
    end
  end

  endpoint :delete_user do |id|
    aws_async_wait :reload do
      user =  Marty::AwsObject.find(id)

      begin
        value  = user.value['api_key']
        Marty::AwsApiKey.where(value: value).destroy_all
      rescue => e
        raise e unless e.message.include?('Invalid API Key')
      end

      Marty::Aws::Cognito.new.admin_delete_user(user.value['username'])
    end
  end

  endpoint :reset_user_password do |id|
    aws_async_wait :reload do
      username = Marty::AwsObject.find(id).value['username']
      Marty::Aws::Cognito.new.admin_reset_password(username)
    end
  end

  def join_api_key r
    v = r.value
    username = v['username']
    email    = v['attributes'].select{|h| h['name'] == 'email'}.first['value']
    api_key  = Marty::AwsApiKey.where(username: username, email: email).first
    r.value['api_key'] = api_key.try(:value)
    r.save!
  end

  def get_records params
    super.each{|r| join_api_key(r)}
  end

  def default_bbar
    [:toggle_user_access, :delete_user, :reset_user_password]
  end
end

AwsCognitoView = Marty::AwsCognitoView
