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
        :data_type,
        :created_dt,
      ]

    c.store_config.merge!(sorters:  [{ property: :name, direction: 'ASC' }])
    c.editing      = :in_form
    c.paging       = :pagination
    c.multi_select = false
  end

  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify('Permission Denied') if
      !config[:permissions][:create]

    begin
      DataGrid.create_from_import(data['name'], data['export'])
      client.success = true
      client.netzke_on_submit_success
    rescue StandardError => exc
      client.netzke_notify(exc.to_s)
    end
  end

  endpoint :edit_window__edit_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    dg = DataGrid.find_by_id(data['id'])

    begin
      dg.update_from_import(data['name'], data['export'])
      client.success = true
      client.netzke_on_submit_success
    rescue StandardError => exc
      client.netzke_notify(exc.to_s)
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

    dg = DataGrid.find_by_id(record_id)

    return client.netzke_notify('No data grid.') unless dg

    meta_rows_raw, h_key_rows, data_rows = dg.export_array
    meta_rows = meta_rows_raw.map do |row|
      # need to escape for HTML, otherwise characters such as >, <,
      # etc. not displayed properly.
      row.map { |field| CGI::escapeHTML(field) }
    end
    res = meta_rows + [[]] + h_key_rows + data_rows

    maxcount = res.map(&:length).max

    client.netzke_client_show_grid maxcount, res, 'Data Grid'
  end

  endpoint :edit_grid do |params|
    record_id = params[:record_id]

    dg = DataGrid.find_by_id(record_id)

    return client.netzke_notify('No data grid.') unless dg

    meta_rows_raw, h_key_rows, data_rows = dg.export_array
    res = h_key_rows + data_rows

    md = dg.metadata
    hdim = md.map { |m| m['dir'] == 'h' && m['attr'] }.select { |v| v }
    vdim = md.map { |m| m['dir'] == 'v' && m['attr'] }.select { |v| v }

    name = "Editing Data Grid '#{dg.name}'"
    client.edit_grid(record_id, hdim, vdim, res, name)
  end

  endpoint :save_grid do |params|
    begin
      rec_id = params['record_id']
      data = params['data']
      data_as_array = data.map do |row|
        row.keys.map { |key| row[key] }
      end
      dg = Marty::DataGrid.mcfly_pt('infinity').find_by(group_id: rec_id)
      vcnt = dg.metadata.select { |md| md['dir'] == 'v' }.count
      hcnt = dg.metadata.select { |md| md['dir'] == 'h' }.count
      exported = dg.export.lines
      sep = exported.each_with_index.detect { |l, i| /^\s*$/.match(l) }.last
      new_data = data_as_array.each_with_index.map do |line, idx|

      #  line = Array.new(vcnt, nil) + line[vcnt..-1] if idx < hcnt
        line.join("\t") + "\r\n"
      end.compact
      to_import = (exported[0..sep] + new_data).join
      dg.update_from_import(dg.name, to_import)
      return false
    rescue StandardError => e
      # marty log
      return e.message
    end
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
      textarea_field(:export, height: 300, hide_label: true),
    ]
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
    c.width = 120
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
