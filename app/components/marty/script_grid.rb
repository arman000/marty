class Marty::ScriptGrid < Marty::Grid
  has_marty_permissions \
  create: [:dev],
  read: :any,
  update: [:dev],
  delete: [:dev]

  def configure(c)
    super

    c.model                  = "Marty::Script"
    c.multi_select           = false
    c.attributes ||= [:name, :created_dt, :tag]
    c.title   ||= I18n.t('scripts', default: "Scripts")
    c.store_config.merge!({sorters: [{property: :name, direction: 'ASC'}]})
  end

  def get_records(params)
    begin
      ts = Marty::Tag.map_to_tag(root_sess[:selected_tag_id]).created_dt
      ts = Mcfly.normalize_infinity(ts)
    rescue
      # if there are no non-DEV tags we get an exception above
      ts = 'infinity'
    end

    tb = model.table_name
    model.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                     ts, ts).scoping do
      super
    end
  end

  action :del do |a|
    a.text     = I18n.t("script_grid.delete")
    a.tooltip  = I18n.t("script_grid.delete")
    a.icon     = :script_delete
    a.disabled = config[:prohibit_delete]
  end

  endpoint :server_delete do |params, this|
    return this.netzke_feedback("Permission Denied") if
      config[:prohibit_delete]

    tag = Marty::Tag.map_to_tag(root_sess[:selected_tag_id])

    return this.netzke_feedback("Can only delete in DEV tag") unless
      tag && tag.isdev?

    super(params, this)
  end

  # override the add_in_form endpoint.  Script creation needs to use
  # the create_script method.
  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify("Permission Denied") if
      !config[:permissions][:create]

    tag = Marty::Tag.map_to_tag(root_sess[:selected_tag_id])

    return client.netzke_notify("Can only add in DEV tag") unless
      tag && tag.isdev?

    name = data["name"]
    script = Marty::Script.create_script(name, "# Script #{name}")

    if script.valid?
      client.success = true
      return client.netzke_on_submit_success
    end

    client.netzke_notify(model_adapter.errors_array(script).join("\n"))
  end

  action :add_in_form do |a|
    a.text     = I18n.t("script_grid.new")
    a.tooltip  = I18n.t("script_grid.new")
    a.icon     = :script_add
    a.disabled = !config[:permissions][:create]
  end

  def default_bbar
    [:add_in_form, :del]
  end

  def default_context_menu
    []
  end

  def default_form_items
    [:name]
  end

  attribute :name do |c|
    c.flex      = 1
    c.text      = I18n.t("script_grid.name")
  end

  attribute :created_dt do |c|
    c.text      = I18n.t("script_grid.created_dt")
    c.format    = "Y-m-d H:i"
    c.read_only = true
  end

  attribute :tag do |c|
    c.text      = I18n.t("script_grid.tag")
    c.flex      = 1
    c.getter    = lambda { |r| r.find_tag.try(:name) }
  end
end

ScriptGrid = Marty::ScriptGrid
