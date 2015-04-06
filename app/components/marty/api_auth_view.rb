class Marty::ApiAuthView < Marty::McflyGridPanel
  has_marty_permissions create: :admin,
                        read: :any,
                        update: :admin,
                        delete: :admin

  def configure(c)
    super

    c.title   = I18n.t('api_auth', default: "API Authorization")
    c.model   = "Marty::ApiAuth"
    c.columns = [:app_name, :api_key, :script_name]

    c.enable_extended_search = false

    c.data_store.sorters = {property: :app_name, direction: 'ASC'}
  end

  column :app_name do |c|
    c.flex = 1
  end

  column :api_key do |c|
    c.flex = 1
  end

  column :script_name do |c|
    c.flex = 1
  end
end

ApiAuthView = Marty::ApiAuthView
