class Marty::ApiAuthView < Marty::McflyGridPanel
  has_marty_permissions create: :admin,
                        read: :any,
                        update: :admin,
                        delete: :admin

  def configure(c)
    super

    c.title      = I18n.t('api_auth', default: "API Authorization")
    c.editing    = :in_form
    c.pagination = :pagination
    c.model      = "Marty::ApiAuth"
    c.attributes = [:aws, :entity_name, :api_key, :script_name]
    c.store_config.merge!({sorters: [{property: :app_name, direction: 'ASC'}]})
  end

  attribute :aws do |c|
    c.width     = 60
    c.read_only = true
    c.text      = "AWS"
    c.type      = :boolean
    c.getter = lambda do |r|
      !!r.parameters['aws_api_key']
    end
    c.sorting_scope = get_json_sorter('parameters', 'aws_api_key')
    c.filterable = true
    c.filter_with = lambda do |rel, value, op|
      rel.where("parameters->>'aws_api_key' IS #{value ? 'NOT' : ''} NULL")
    end
  end

  attribute :entity_name do |c|
    c.flex = 1
    c.text = "Entity Name"
    c.getter = lambda do |r|
      aws    = !!r.parameters['aws_api_key']
      entity = r.entity
      entity ? entity.name : (aws ? nil : r.app_name)
    end
  end

  attribute :api_key do |c|
    c.flex = 1
  end

  attribute :script_name do |c|
    c.flex = 1
  end
end

ApiAuthView = Marty::ApiAuthView
