{
  initComponent: function () {
    var me = this;
    me.callParent();

    var tag_grid = me.netzkeGetComponent('tag_grid').getView();
    var script_grid = me.netzkeGetComponent('script_grid').getView();
    var script_form = me.netzkeGetComponent('script_form');

    tag_grid.getSelectionModel().on('selectionchange',
      function (self, records) {

        if (records[0] == null)
          return;

        var tag_id = records[0].get('id');
        me.server.selectTag({
          tag_id: tag_id
        });
        script_grid.getStore().load();
        var script_name = null;
        script_form.server.netzkeLoad({
          script_name: script_name
        });
      }, me);

    script_grid.getSelectionModel().on('selectionchange',
      function (self, records) {

        if (script_grid.getStore().isLoading() == true)
          return;

        if (records[0] == null)
          return;

        var script_name = records[0].get('name');
        me.server.selectScript({
          script_name: script_name
        });
        script_form.server.netzkeLoad({
          script_name: script_name
        });
      }, me);
  },

  scriptRefresh: function (script_name) {
    if (!script_name) {
      this.server.selectScript({});
      this.netzkeReload();
    } else {
      this.server.selectScript({
        script_name: script_name
      });
      this.netzkeGetComponent('tag_grid').getStore().load();
      this.netzkeGetComponent('script_grid').getStore().load();
      this.netzkeGetComponent('script_form').server.netzkeLoad({
        script_name: script_name
      });
    }
  },

}
