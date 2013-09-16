class Marty::ImportSynonymView < Marty::CmGridPanel
  has_marty_permissions	create: :admin,
			read: :any,
			update: :admin,
			delete: :admin

  def configure(c)
    super

    c.title 	= I18n.t('import_synonym', default: "ImportSynonym")
    c.model 	= "Marty::ImportSynonym"
    c.columns 	= [:import_type__name, :synonym, :internal_name]

    c.enable_extended_search 	= false

    c.data_store.sorters = {property: :import_type__name, direction: 'ASC'}
  end

  column :import_type__name do |c|
    c.flex = 1
  end

  column :synonym do |c|
    c.flex = 1
  end

  column :internal_name do |c|
    c.flex = 1
  end

end

ImportSynonymView = Marty::ImportSynonymView
