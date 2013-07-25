class Marty::ImportSynonymView < Marty::CmGridPanel

  def configure(c)
    super

    c.title 	= I18n.t('import_synonym', default: "ImportSynonym")
    c.model 	= "Marty::ImportSynonym"
    c.columns 	= [:import_type__name, :synonym, :internal_name]

    c.enable_extended_search 	= false
    c.enable_edit_in_form 	= self.class.has_admin_perm?
    c.prohibit_update 		= !self.class.has_admin_perm?
    c.prohibit_delete 		= !self.class.has_admin_perm?
    c.prohibit_create 		= !self.class.has_admin_perm?
    c.prohibit_read 		= !self.class.has_any_perm?
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
