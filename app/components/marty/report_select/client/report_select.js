{
  initComponent: function () {
    var me = this;
    me.callParent();

    var tag_grid = me.netzkeGetComponent('tag_grid').getView();
    var script_grid = me.netzkeGetComponent('script_grid').getView();
    var nodename = me.getForm().findField('nodename');

    nodename.on('select', function (self, record) {
      if (record instanceof Array) {
        record = record[0]
      }
      var data = record && record.data;
      me.server.selectNode({
        node: data.value
      });
    });

    tag_grid.getSelectionModel().on('selectionchange',
      function (self, records) {
        var tag_id = records[0].get('id');
        me.server.selectTag({
          tag_id: tag_id
        });
        script_grid.getStore().load();
      }, me);

    script_grid.getSelectionModel().on('selectionchange',
      function (self, records) {
        if (script_grid.getStore().isLoading() == true) return;

        if (records[0] == null)
          return;

        var script_name = records[0].get('name');
        me.server.selectScript({
          script_name: script_name
        });
        nodename.reset();
        nodename.store.load({
          params: {}
        });
      }, me);
  },

  parentSelectReport: function () {
    this.netzkeGetParentComponent().selectReport();
  }
}
