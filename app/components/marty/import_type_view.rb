class Marty::ImportTypeView < Marty::CmGridPanel
  has_marty_permissions	create: :admin,
			read: :any,
			update: :admin,
			delete: :admin

  def configure(c)
    super

    c.title 	= I18n.t('import_type', default: "ImportType")
    c.model 	= "Marty::ImportType"
    c.columns 	= [:name, :model_name, :synonym_fields, :cleaner_function]

    c.enable_extended_search 	= false

    c.data_store.sorters = {property: :name, direction: 'ASC'}
  end

  column :name do |c|
    c.flex = 1
  end

  column :model_name do |c|
    c.flex = 1
  end

  column :synonym_fields do |c|
    c.flex = 1
  end

  column :cleaner_function do |c|
    c.flex = 1
  end

end

ImportTypeView = Marty::ImportTypeView
