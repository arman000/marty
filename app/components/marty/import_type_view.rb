class Marty::ImportTypeView < Marty::CmGridPanel

  def configure(c)
    super

    c.title 	= I18n.t('import_type', default: "ImportType")
    c.model 	= "Marty::ImportType"
    c.columns 	= [:name, :model_name, :synonym_fields, :cleaner_function]

    c.enable_extended_search 	= false
    c.enable_edit_in_form 	= self.class.has_admin_perm?
    c.prohibit_update 		= !self.class.has_admin_perm?
    c.prohibit_delete 		= !self.class.has_admin_perm?
    c.prohibit_create 		= !self.class.has_admin_perm?
    c.prohibit_read 		= !self.class.has_any_perm?

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
