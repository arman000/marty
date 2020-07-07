({
  initComponent() {
    const me = this;
    me.callParent();

    const tagGrid = me.netzkeGetComponent("tag_grid").getView();
    const scriptGrid = me.netzkeGetComponent("script_grid").getView();
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

    tagGrid.getSelectionModel().on(
      "selectionchange",
      function(self, records) {
        const tagId = records[0].get("id");
        me.server.selectTag({
          tag_id: tagId
        });
        scriptGrid.getStore().load();
      },
      me
    );

    scriptGrid.getSelectionModel().on(
      "selectionchange",
      function(self, records) {
        if (scriptGrid.getStore().isLoading() == true) return;

        if (records[0] == null) return;

        const scriptName = records[0].get("name");
        me.server.selectScript({
          script_name: scriptName
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
