class Marty::ScriptGrid < Marty::CmGridPanel

  def configure(c)
    super

    # Hacky fix to allow for testing
    c.allow_edit = true if
      c.allow_edit.nil? &&
      ENV["RAILS_ENV"] == "test" &&
      self.class.current_user_roles.include?(:dev)

    c.title ||= I18n.t('scripts', default: "Scripts")

    c.model			= "Marty::Script"
    c.enable_extended_search	= false
    c.prohibit_update		= true
    c.prohibit_delete		= true
    c.prohibit_create		= !c.allow_edit
    c.prohibit_read		= !self.class.has_any_perm?

    c.columns ||= [:name, :created_dt, :status]

    c.data_store.sorters = {property: :name, direction: 'ASC'}
  end

  def get_tag_dt
    tag = Marty::Tag.find_by_id(session[:selected_tag_id])

    return 'infinity' unless tag

    Mcfly.normalize_infinity(tag.created_dt)
  end

  def get_data(*args)
    # mostly copied from Marty::McflyGridPanel.get_data

    ts = get_tag_dt

    tb = data_class.table_name
    data_class.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                     ts, ts).scoping do
      super
    end
  end

  # override the add_in_form endpoint.  Script creation needs to use
  # the create_script method.
  endpoint :add_window__add_form__netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    if config[:prohibit_create]
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
    a.text	= I18n.t("script_grid.new")
    a.tooltip	= I18n.t("script_grid.new")
    a.icon	= :script_add
    a.disabled	= config[:prohibit_create]
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
    c.flex	= 1
    c.text	= I18n.t("script_grid.name")
  end

  column :created_dt do |c|
    c.text	= I18n.t("script_grid.created_dt")
    c.format	= "Y-m-d H:i"
    c.read_only = true
  end

  column :status do |c|
    c.text	= I18n.t("script_grid.status")
    c.flex	= 2
    c.getter	= lambda { |r| "FIXME" }
  end
end

ScriptGrid = Marty::ScriptGrid
