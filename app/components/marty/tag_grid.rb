class Marty::TagGrid < Marty::Grid
  has_marty_permissions \
    read:   :any,
    create: :dev

  def configure(c)
    super

    c.header       = false
    c.model        = 'Marty::Tag'
    c.multi_select = true

    c.attributes ||= [:name, :created_dt, :user__name, :comment]

    c.store_config.merge!(sorters: [{ property: :created_dt,
                                      direction: 'DESC' }])
  end

  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify('Permission Denied') if
      !config[:permissions][:create]

    # FIXME: disallow tag creation when no script has been modified?

    tag = Marty::Tag.do_create(nil, data['comment'])

    if tag.valid?
      client.success = true
      client.netzke_on_submit_success
      return
    end

    client.netzke_notify(model_adapter.errors_array(tag).join("\n"))
  end

  action :add_in_form do |a|
    a.text     = I18n.t('tag_grid.new')
    a.tooltip  = I18n.t('tag_grid.new')
    a.icon_cls = 'fa fa-clock glyph'
    a.disabled = !config[:permissions][:create]
  end

  action :download do |a|
    a.text     = I18n.t('tag_grid.dl')
    a.tooltip  = I18n.t('tag_grid.dl')
    a.icon_cls = 'fa fa-file-export glyph'
  end

  action :diff do |a|
    a.text     = I18n.t('tag_grid.diff')
    a.tooltip  = I18n.t('tag_grid.diff')
    a.icon_cls = 'fa fa-bars glyph'
  end

  def default_bbar
    [:add_in_form, :download, :diff]
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
    c.text   = 'Date/Time'
    c.format = 'Y-m-d H:i'
    c.hidden = true
  end

  attribute :user__name do |c|
    c.width  = 100
  end

  attribute :comment do |c|
    c.width  = 100
    c.flex   = 1
  end

  endpoint :diff do |params|
    next client.netzke_notify('please select no more than two tags') if
      params.length > 2

    tag1, tag2 = params.map { |h| h['name'] }
    begin
      p = Marty::Util.gen_report_path(
        'ScriptReport',
        'DiffReport',
        {
          'tag_name_1' => tag1,
          'tag_name_2' => tag2
        },
      )

      client.download_report(p) if p.present?
    rescue StandardError => e
      client.netzke_notify "ERROR: #{e}"
    end
  end

  endpoint :download do |params|
    next client.netzke_notify('please select one tag') if params.length != 1

    tag_name = params[0]['name']
    next 'please select non-DEV tag' if tag_name == 'DEV'

    begin
      p = Marty::Util.gen_report_path(
        'ScriptReport',
        'DownloadAll',
        {
          title: "Scripts-#{tag_name}",
          tag_name: tag_name,
        },
      )

      client.download_report(p)
    rescue StandardError => e
      client.netzke_notify "ERROR: #{e}"
    end
  end
end

TagGrid = Marty::TagGrid
