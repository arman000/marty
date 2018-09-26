class Marty::Aws::Cognito::PoolView < Marty::Aws::Grid
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
    field_maker(a.to_s, h, :value, ['_attributes'])
  end

  def configure(c)
    super
    c.title      = "AWS Cognito Users"
    c.attributes = ATTRIBUTES.keys + NESTED_ATTRIBUTES.keys
  end

  client_class do |c|
    c.netzke_on_do_toggle_user_access = l(<<-JS)
    function(params) {
      var me = this;
      Ext.Msg.confirm(
        'Toggle User Access',
        Ext.String.format('Are you sure?'),
        function (btn, value, cfg) {
          btn == "yes" && me.server.toggleUserAccess();
        });
    }
    JS

    c.netzke_on_do_reset_user_password = l(<<-JS)
    function(params) {
      var me = this;
      Ext.Msg.confirm(
        'Reset User Password',
        Ext.String.format('Are you sure?'),
        function (btn, value, cfg) {
          btn == "yes" && me.server.resetUserPassword();
        });
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
    begin
      user   = Marty::Aws::Object.find(client_config['selected'])
      username = user.username

      cog = Marty::Aws::Cognito.new
      user.enabled ? cog.admin_disable_user(username) :
        cog.admin_enable_user(username)
      client.reload
    rescue => e
      client.netzke_notify(e.message)
    end
    return
  end

  endpoint :reset_user_password do
    begin
      username = Marty::Aws::Object.find(client_config['selected']).username
      Marty::Aws::Cognito.new.admin_reset_password(username)
      client.reload
    rescue => e
      client.netzke_notify(e.message)
    end
    return
  end

  def get_api_key r
    email = r._attributes.select{|h| h['name'] == 'email'}.first['value']
    Marty::ApiAuth.where(obsoleted_dt: 'infinity').where(
      "parameters->'aws_api_key'->>'username' = ? AND "\
      "parameters->'aws_api_key'->>'email'    = ?",
      r.username,
      email
    ).first.try(:api_key)
  end

  def get_records params
    super.map do |r|
      r.value['api_key'] = get_api_key(r)
      r.save!
      r
    end
  end

  def default_bbar
    [:do_toggle_user_access, :do_reset_user_password]
  end
end

AwsCognitoPoolView = Marty::Aws::Cognito::PoolView
