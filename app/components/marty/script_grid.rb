class Marty::ScriptGrid < Marty::CmGridPanel
  def configure(c)
    super

    # FIXME: overwriting allow_edit

    c.allow_edit = self.class.current_user_roles.include?(:dev) &&
      get_tag_dt == 'infinity'

    c.title ||= I18n.t('scripts', default: "Scripts")

    c.model                  = "Marty::Script"
    c.enable_extended_search = false
    c.prohibit_update        = true
    c.prohibit_delete        = true
    c.prohibit_create        = !c.allow_edit
    c.prohibit_read          = !self.class.has_any_perm?

    c.columns ||= [:name, :created_dt, :tag]

    c.data_store.sorters = {
      property: :name,
      direction: 'ASC',
    }
  end

  def get_tag_dt
    tag = Marty::Tag.find_by_id(session[:selected_tag_id])
    tag ? Mcfly.normalize_infinity(tag.created_dt) : 'infinity'
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

    return this.netzke_feedback("Permission Denied") if
      config[:prohibit_create]

    name = data["name"]
    script = Marty::Script.create_script(name, "# Script #{name}")

    if script.valid?
      this.success = true
      return this.on_submit_success
    end

    data_adapter.errors_array(script).each do |error|
      flash :error => error
    end
    this.netzke_feedback(@flash)
  end

  action :add_in_form do |a|
    a.text     = I18n.t("script_grid.new")
    a.tooltip  = I18n.t("script_grid.new")
    a.icon     = :script_add
    a.disabled = config[:prohibit_create]
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
    c.flex      = 1
    c.text      = I18n.t("script_grid.name")
  end

  column :created_dt do |c|
    c.text      = I18n.t("script_grid.created_dt")
    c.format    = "Y-m-d H:i"
    c.read_only = true
  end

  column :tag do |c|
    c.text      = I18n.t("script_grid.tag")
    c.flex      = 1
    c.getter    = lambda { |r| r.find_tag.try(:name) }
  end
end

ScriptGrid = Marty::ScriptGrid
