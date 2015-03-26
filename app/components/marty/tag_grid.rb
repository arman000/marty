class Marty::TagGrid < Marty::CmGridPanel
  has_marty_permissions \
  read:   :any,
  create: :dev

  def configure(c)
    super

    c.header       = false
    c.model        = "Marty::Tag"
    c.multi_select = false

    c.columns ||= [:name, :created_dt, :user__name, :comment]

    c.data_store.sorters = {
      property: :created_dt,
      direction: 'DESC',
    }
  end

  endpoint :add_window__add_form__netzke_submit do |params, this|
    data = ActiveSupport::JSON.decode(params[:data])

    return this.netzke_feedback("Permission Denied") if
      config[:prohibit_create]

    # FIXME: disallow tag creation when no script has been modified?

    tag = Marty::Tag.do_create(nil, data["comment"])

    if tag.valid?
      this.success = true
      this.on_submit_success
      return
    end

    data_adapter.errors_array(tag).each do |error|
      flash :error => error
    end

    this.netzke_feedback(@flash)
  end

  action :add_in_form do |a|
    a.text     = I18n.t("tag_grid.new")
    a.tooltip  = I18n.t("tag_grid.new")
    a.icon     = :time_add
    a.disabled = config[:prohibit_create]
  end

  def default_bbar
    [:add_in_form]
  end

  def default_context_menu
    []
  end

  def default_fields_for_forms
    [:comment]
  end

  column :name do |c|
  end

  column :created_dt do |c|
    c.text   = "Date/Time"
    c.format = "Y-m-d H:i"
    c.hidden = true
  end

  column :user__name do |c|
    c.width  = 100
  end

  column :comment do |c|
    c.width  = 100
    c.flex   = 1
  end

end

TagGrid = Marty::TagGrid
