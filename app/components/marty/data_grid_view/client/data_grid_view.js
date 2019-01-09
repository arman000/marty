{
  netzkeShowGrid: function (options = {}) {
    var dg = options.dataGrid || 'data_grid'
    var title_str = options.titleStr || 'Data Grid'

    var sel = this.getSelectionModel().getSelection()[0];
    var record_id = sel && sel.getId();
    this.server.showGrid({
      record_id: record_id,
      data_grid: dg,
      title_str: title_str
    });
  },

  netzkeClientShowGrid: function (count, data, title_str) {
    var columns = [];
    var fields = [];

    for (var i = 0; i < count; i++) {
      fields.push("a" + i);
      columns.push({
        dataIndex: "a" + i,
        text: i,
        flex: 1
      });
    }

    Ext.create('Ext.Window', {
      height: "80%",
      width: "80%",
      x: 0,
      y: 0,
      autoWidth: true,
      modal: true,
      autoScroll: true,
      title: title_str,
      items: {
        xtype: 'grid',
        border: false,
        hideHeaders: false,
        columns: columns,
        store: Ext.create('Ext.data.ArrayStore', {
          fields: fields,
          data: data,
        })
      },
    }).show();
  },
}
