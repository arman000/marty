class Marty::TagGrid < Marty::Grid
  has_marty_permissions \
  read:   :any,
  create: :dev

  def configure(c)
    super

    c.header       = false
    c.model        = "Marty::Tag"
    c.multi_select = false

    c.attributes ||= [:name, :created_dt, :user__name, :comment]

    c.store_config.merge!({sorters: [{property: :created_dt,
                                      direction: 'DESC'}]})
  end

  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify("Permission Denied") if
      !config[:permissions][:create]

    # FIXME: disallow tag creation when no script has been modified?

    tag = Marty::Tag.do_create(nil, data["comment"])

    if tag.valid?
      client.success = true
      client.netzke_on_submit_success
      return
    end

    model_adapter.errors_array(tag).each do |error|
      flash :error => error
    end

    client.netzke_notify(@flash)
  end

  action :add_in_form do |a|
    a.text     = I18n.t("tag_grid.new")
    a.tooltip  = I18n.t("tag_grid.new")
    a.icon     = :time_add
    a.disabled = !config[:permissions][:create]
  end

  def default_bbar
    [:add_in_form]
  end

  def default_context_menu
    []
  end

  def default_form_items
    [:comment]
  end

  attribute :name do |c|
  end

  attribute :created_dt do |c|
    c.text   = "Date/Time"
    c.format = "Y-m-d H:i"
    c.hidden = true
  end

  attribute :user__name do |c|
    c.width  = 100
  end

  attribute :comment do |c|
    c.width  = 100
    c.flex   = 1
  end

end

TagGrid = Marty::TagGrid
