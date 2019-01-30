class Marty::ApiAuthView < Marty::McflyGridPanel
  has_marty_permissions create: :admin,
                        read: :any,
                        update: :admin,
                        delete: :admin

  def configure(c)
    super

    c.title   = I18n.t('api_auth', default: "API Authorization")
    c.model   = "Marty::ApiAuth"
    c.attributes = [:app_name, :api_key, :script_name]
    c.store_config.merge!(sorters: [{ property: :app_name, direction: 'ASC' }])
  end

  attribute :app_name do |c|
    c.flex = 1
  end

  attribute :api_key do |c|
    c.flex = 1
  end

  attribute :script_name do |c|
    c.flex = 1
  end
end

ApiAuthView = Marty::ApiAuthView
