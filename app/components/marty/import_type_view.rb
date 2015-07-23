class Marty::ImportTypeView < Marty::Grid
  has_marty_permissions \
  create: :admin,
  read: :any,
  update: :admin,
  delete: :admin

  def configure(c)
    super

    c.title   = I18n.t('import_type', default: "ImportType")
    c.model   = "Marty::ImportType"
    c.columns =
      [
       :name,
       :role__name,
       :db_model_name,
       :cleaner_function,
       :validation_function,
       :preprocess_function,
      ]

    c.enable_extended_search = false

    c.data_store.sorters = {property: :name, direction: 'ASC'}
  end

  column :name do |c|
    c.flex = 1
  end

  column :role__name do |c|
    c.width = 150
  end

  column :db_model_name do |c|
    c.flex = 1
  end

  column :cleaner_function do |c|
    c.flex = 1
  end

  column :validation_function do |c|
    c.flex = 1
  end

  column :preprocess_function do |c|
    c.flex = 1
  end
end

ImportTypeView = Marty::ImportTypeView
