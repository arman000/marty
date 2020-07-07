class Marty::ImportTypeView < Marty::Grid
  has_marty_permissions \
    create: :admin,
    read: :any,
    update: :admin,
    delete: :admin

  def configure(c)
    super

    c.title   = I18n.t('import_type', default: 'ImportType')
    c.model   = 'Marty::ImportType'
    c.attributes =
      [
        :name,
        :role,
        :db_model_name,
        :cleaner_function,
        :validation_function,
        :preprocess_function,
      ]
    c.store_config.merge!(sorters: [{ property: :name, direction: 'ASC' }])
  end

  attribute :name do |c|
    c.flex = 1
  end

  attribute :role do |c|
    c.width = 150

    store = ::Marty::UserRole.role_values.sort

    c.editor_config = {
      multi_select: false,
      store:        store,
      type:         :string,
      xtype:        :combo,
    }
  end

  attribute :db_model_name do |c|
    c.flex = 1
  end

  attribute :cleaner_function do |c|
    c.flex = 1
  end

  attribute :validation_function do |c|
    c.flex = 1
  end

  attribute :preprocess_function do |c|
    c.flex = 1
  end
end

ImportTypeView = Marty::ImportTypeView
