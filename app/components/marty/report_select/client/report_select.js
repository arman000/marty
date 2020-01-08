({
  initComponent() {
    const me = this;
    me.callParent();

    const tag_grid = me.netzkeGetComponent("tag_grid").getView();
    const script_grid = me.netzkeGetComponent("script_grid").getView();
    const nodename = me.getForm().findField("nodename");

    nodename.on("select", function(self, record) {
      if (record instanceof Array) {
        record = record[0];
      }
      const data = record && record.data;
      me.server.selectNode({
        node: data.value
      });
    });

    tag_grid.getSelectionModel().on(
      "selectionchange",
      function(self, records) {
        const tag_id = records[0].get("id");
        me.server.selectTag({
          tag_id
        });
        script_grid.getStore().load();
      },
      me
    );

    script_grid.getSelectionModel().on(
      "selectionchange",
      function(self, records) {
        if (script_grid.getStore().isLoading() == true) return;

        if (records[0] == null) return;

        const script_name = records[0].get("name");
        me.server.selectScript({
          script_name
        });
        nodename.reset();
        nodename.store.load({
          params: {}
        });
      },
      me
    );
  },

  parentSelectReport() {
    this.netzkeGetParentComponent().selectReport();
  }
});
