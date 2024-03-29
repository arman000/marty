module Marty; class DataGridView < McflyGridPanel
  has_marty_permissions create: [:admin, :dev],
                        read: :any,
                        update: [:admin, :dev],
                        delete: [:admin, :dev]

  include Extras::Layout

  # show_grid_js and client_show_grid_js have specific
  # handles so they can be used by various other components
  # FIXME: add the ability to pull specific functions
  # from other component javascripts or add a base to pull from
  def self.show_grid_js(options = {})
    dg        = options[:data_grid] || 'data_grid'
    title_str = options[:title_str] || 'Data Grid'

    javascript = l(<<-JS)
    function() {
       var sel = this.getSelectionModel().getSelection()[0];
       var record_id = sel && sel.getId();
       this.server.showGrid({record_id: record_id,
                            data_grid: "#{dg}",
                            title_str: "#{title_str}"});
    }
    JS
    javascript
  end

  def self.client_show_grid_js
    javascript = l(<<-JS)
    function(count, data, title_str) {
       var columns = [];
       var fields  = [];

       for (var i=0; i<count; i++) {
          fields.push("a" + i);
          columns.push({dataIndex: "a" + i, text: i, flex: 1});
       }

       Ext.create('Ext.Window', {
         height:        "80%",
         width:         "80%",
         x:             0,
         y:             0,
         autoWidth:     true,
         modal:         true,
         autoScroll:    true,
         title:         title_str,
         items: {
           xtype:       'grid',
           border:      false,
           hideHeaders: false,
           columns:     columns,
           store:       Ext.create('Ext.data.ArrayStore', {
             fields: fields,
             data: data,
             })
         },
      }).show();
    }
    JS
    javascript
  end

  def self.edit_grid_js(options = {})
    dg        = options[:data_grid] || 'data_grid'
    title_str = options[:title_str] || 'Data Grid'

    javascript = l(<<-JS)
    function() {
       var sel = this.getSelectionModel().getSelection()[0];
       var record_id = sel && sel.getId();
       this.server.editGrid({record_id: record_id,
                            data_grid: "#{dg}",
                            title_str: "#{title_str}"});
    }
    JS
    javascript
  end

  client_class do |c|
    c.include :data_grid_edit
    c.netzke_show_grid        = DataGridView.show_grid_js
    c.netzke_client_show_grid = DataGridView.client_show_grid_js
    c.netzke_edit_grid        = DataGridView.edit_grid_js
  end

  def configure(c)
    super

    c.title   = I18n.t('data_grid')
    c.model   = 'Marty::DataGrid'
    c.attributes =
      [
        :name,
        :vcols,
        :hcols,
        :lenient,
        :strict_null_mode,
        :data_type,
        :constraint,
        :perm_view,
        :perm_edit_data,
        :perm_edit_all,
        :created_dt,
      ]

    c.store_config.merge!(sorters:  [{ property: :name, direction: 'ASC' }])
    c.editing      = :in_form
    c.paging       = :pagination
    c.multi_select = false
  end

  def set_perms(dg, data)
    permstrs = %w[perm_view perm_edit_data perm_edit_all]
    view, edit_data, edit_all = data.values_at(*permstrs).map do |plist|
      Marty::RoleType.from_nice_names(plist)
    end
    dg.permissions = {
      view: view.presence || [],
      edit_data: edit_data.presence || [],
      edit_all: edit_all.presence || [],
    }
    dg.save!
  end

  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify('Permission Denied') if
      !config[:permissions][:create]

    begin
      dg = DataGrid.create_from_import(data['name'], data['export'])
      set_perms(dg, data)
      client.success = true
      client.netzke_on_submit_success
    rescue StandardError => e
      client.netzke_notify(e.to_s)
    end
  end

  endpoint :edit_window__edit_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    dg = DataGrid.find_by(id: data['id'])

    begin
      dg.update_from_import(data['name'], data['export'])
      set_perms(dg, data)
      client.success = true
      client.netzke_on_submit_success
    rescue StandardError => e
      client.netzke_notify(e.to_s)
    end
  end

  action :show_grid do |a|
    a.text     = 'Show Grid'
    a.icon_cls = 'fa fa-th-large glyph'
    a.handler  = :netzke_show_grid
  end

  action :edit_grid do |a|
    a.text     = 'Edit Grid'
    a.icon_cls = 'fa fa-th-large glyph'
    a.handler  = :netzke_edit_grid
  end

  endpoint :show_grid do |params|
    record_id = params[:record_id]

    dg = DataGrid.find_by(id: record_id)

    return client.netzke_notify('No data grid.') unless dg

    meta_rows_raw, h_key_rows_raw, data_rows = dg.export_array
    meta_rows = meta_rows_raw.map do |row|
      # need to escape for HTML, otherwise characters such as >, <,
      # etc. not displayed properly.
      row.map { |field| CGI::escapeHTML(field) }
    end

    h_key_rows_with_comments = h_key_rows_raw.map do |row|
      row += ['']
    end

    h_key_rows_with_comments[-1][-1] = 'Comments:' if h_key_rows_with_comments.any?

    res = meta_rows + [[]] + h_key_rows_with_comments + data_rows

    maxcount = res.map(&:length).max

    client.netzke_client_show_grid maxcount, res, 'Data Grid'
  end

  def self.get_edit_permission(_permissions, config)
    if config[:permissions][:update]
      'edit_all'
    else
      'view'
    end
  end

  endpoint :edit_grid do |params|
    record_id = params[:record_id]

    dg = DataGrid.find_by(id: record_id)

    return client.netzke_notify('No data grid.') unless dg

    meta_rows_raw, h_key_rows, data_rows = dg.export_array
    h_key_rows_with_comments = h_key_rows.map { |row| row += [''] }
    res = h_key_rows_with_comments + data_rows

    md = dg.metadata
    hdim = md.map { |m| m['dir'] == 'h' && m['attr'] }.select { |v| v }
    vdim = md.map { |m| m['dir'] == 'v' && m['attr'] }.select { |v| v }
    hdim_en = hdim.map { |d| I18n.t('attributes.' + d, default: d) }
    vdim_en = vdim.map { |d| I18n.t('attributes.' + d, default: d) }
    perm = self.class.get_edit_permission(dg.permissions, config)
    # should never happen
    return client.netzke_notify('No permission to edit/view grid.') unless perm

    doing = case perm
            when 'view'
              'Viewing'
            when 'edit_all'
              'Editing (all)'
            when 'edit_data'
              'Editing (data only)'
            end
    name = "#{doing} Data Grid '#{dg.name}'"

    client.edit_grid(record_id, hdim_en, vdim_en, res, name, perm)
  end

  endpoint :save_grid do |params|
    rec_id = params['record_id']
    dg = Marty::DataGrid.mcfly_pt('infinity').find_by(group_id: rec_id)
    user_perm = self.class.get_edit_permission(dg.permissions, config)

    SaveGrid.call(params, dg, user_perm)
  end

  def default_bbar
    [:show_grid, :edit_grid] + super
  end

  def default_context_menu
    []
  end

  def default_form_items
    [
      :name,
      :perm_view, :perm_edit_data, :perm_edit_all,
      textarea_field(:export, height: 300, hide_label: true),
    ]
  end

  ['view', 'edit_data', 'edit_all'].each do |p|
    s = ('perm_' + p).to_s
    attribute s do |c|
      c.width   = 100
      c.flex    = 1
      c.label   = I18n.t("data_grid_view_perms.#{s}")
      c.type    = :string
      c.getter = lambda do |r|
        Marty::RoleType.to_nice_names(r.permissions[p].sort)
      end
      store = Marty::RoleType.to_nice_names(::Marty::RoleType.get_all.sort.map)

      # edit does not work without this dummy setter
      c.setter = ->(r, v) {}

      c.editor_config = {
        multi_select: true,
        empty_text:   I18n.t('user_grid.select_roles'),
        store:        store,
        type:         :string,
        xtype:        :combo,
      }
    end
  end

  component :edit_window do |c|
    super(c)
    c.width = 700
  end

  component :add_window do |c|
    super(c)
    c.width = 700
  end

  attribute :name do |c|
    c.width = 400
  end

  attribute :constraint do |c|
    c.width = 150
  end

  attribute :hcols do |c|
    c.label  = 'Horizontal Attrs'
    c.width  = 200
    c.getter = lambda { |r|
      r.dir_infos('h').map { |inf| inf['attr'] }.join(', ')
    }
  end

  attribute :vcols do |c|
    c.label  = 'Vertical Attrs'
    c.width  = 200
    c.getter = lambda { |r|
      r.dir_infos('v').map { |inf| inf['attr'] }.join(', ')
    }
  end

  attribute :lenient do |c|
    c.width  = 75
  end

  attribute :strict_null_mode do |c|
    c.width  = 100
  end

  attribute :data_type do |c|
    c.label  = 'Data Type'
    c.width  = 200
  end

  attribute :created_dt do |c|
    c.label     = I18n.t('updated_at')
    c.format    = 'Y-m-d H:i'
    c.read_only = true
  end
end; end

DataGridView = Marty::DataGridView
