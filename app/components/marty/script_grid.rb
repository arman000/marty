class Marty::ScriptGrid < Marty::CmGridPanel

  def configure(c)
    super

    c.title ||= I18n.t('scripts', default: "Scripts")
    c.model 			= "Marty::Script"
    c.enable_extended_search 	= false
    c.scope 			||= ["obsoleted_dt = 'infinity'"]
    c.prohibit_update 		= true
    c.prohibit_delete 		= true
    c.prohibit_create 		= !self.class.has_dev_perm?
    c.prohibit_read 		= !self.class.has_any_perm?

    c.columns ||= [:name, :version, :created_dt, :status]

    c.data_store.sorters = {property: :name, direction: 'ASC'}
  end

  # override the add_in_form endpoint.  Script creation needs to use
  # the create_script method.
  endpoint :add_window__add_form__netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    unless self.class.has_dev_perm?
      this.netzke_feedback "Permission Denied"
      return
    end

    script = Marty::Script.create_script(data["name"])
    if script.valid?
      this.success = true
      this.on_submit_success
    else
      data_adapter.errors_array(script).each do |error|
        flash :error => error
      end
      this.netzke_feedback(@flash)
    end
  end

  action :add_in_form do |a|
    a.text 	= I18n.t("script_grid.new")
    a.tooltip  	= I18n.t("script_grid.new")
    a.icon 	= :script_add
    a.disabled 	= config[:prohibit_create]
  end

  def default_bbar
    [:add_in_form]
  end

  def default_context_menu
    []
  end

  def default_fields_for_forms
    [:name]
  end

  column :name do |c|
    c.flex 	= 1
    c.text 	= I18n.t("script_grid.name")
  end

  column :version do |c|
    c.width 	= 60
    c.text 	= I18n.t("script_grid.version")
  end

  column :created_dt do |c|
    c.text 	= I18n.t("script_grid.created_dt")
    c.format 	= "Y-m-d H:i"
    c.read_only = true
  end

  # There's always a log entry with version DEV.  this entry is
  # active if there's an associated dscript entry which referes to
  # it.  Otherwise, the log entry refers to a checked-in version.

  column :status do |c|
    c.text 	= I18n.t("script_grid.status")
    c.flex 	= 2
    c.getter 	= lambda { |r|
      dscript = Marty::Dscript.find_by_script_id(r.id)
      # if we have a dscript, then it's checked out.
      dscript ? dscript.user.to_s : "---"
    }
  end
end

ScriptGrid = Marty::ScriptGrid
