class Marty::ScriptGrid < Marty::Grid
  has_marty_permissions \
  create: [:dev],
  read: :any,
  update: [:dev],
  delete: [] # [:dev]

  def configure(c)
    super

    c.model                  = "Marty::Script"
    c.enable_extended_search = false
    c.multi_select           = false

    c.columns ||= [:name, :created_dt, :tag]
    c.title   ||= I18n.t('scripts', default: "Scripts")

    c.data_store.sorters = {
      property: :name,
      direction: 'ASC',
    }
  end

  def get_records(params)
    begin
      ts = Marty::Tag.map_to_tag(root_sess[:selected_tag_id]).created_dt
      ts = Mcfly.normalize_infinity(ts)
    rescue
      # if there are no non-DEV tags we get an exception above
      ts = 'infinity'
    end

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

    tag = Marty::Tag.map_to_tag(root_sess[:selected_tag_id])

    return this.netzke_feedback("Can only add in DEV tag") unless
      tag && tag.isdev?

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
