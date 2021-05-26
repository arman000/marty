class Marty::HttpApiAuthView < Marty::McflyGridPanel
  has_marty_permissions create: :admin,
    read: :admin,
    update: :admin,
    delete: :admin

  def configure(c)
    super

    c.title   = I18n.t('api_auth', default: 'HTTP API Authorization')
    c.model   = 'Marty::HttpApiAuth'
    c.attributes = [:app_name, :token, :authorizations]
    c.store_config.merge!(sorters: [{ property: :app_name, direction: 'ASC' }])
  end

  attribute :app_name do |c|
    c.flex = 1
  end

  attribute :token do |c|
    c.flex = 1
  end

  attribute :authorizations do |c|
    c.flex = 1
  end
end

HttpApiAuthView = Marty::HttpApiAuthView
