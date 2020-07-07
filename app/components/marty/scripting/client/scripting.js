({
  initComponent() {
    const me = this;
    me.callParent();

    const tagGrid = me.netzkeGetComponent("tag_grid").getView();
    const scriptGrid = me.netzkeGetComponent("script_grid").getView();
    const scriptForm = me.netzkeGetComponent("script_form");

    tagGrid.getSelectionModel().on(
      "selectionchange",
      function(self, records) {
        if (records[0] == null) return;

        const tagId = records[0].get("id");
        me.server.selectTag({
          tag_id: tagId
        });
        scriptGrid.getStore().load();
        const scriptName = null;
        scriptForm.server.netzkeLoad({
          script_name: scriptName
        });
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
        scriptForm.server.netzkeLoad({
          script_name: scriptName
        });
      },
      me
    );
  },

  scriptRefresh(scriptName) {
    if (!scriptName) {
      this.server.selectScript({});
      this.netzkeReload();
    } else {
      this.server.selectScript({
        script_name: scriptName
      });
      this.netzkeGetComponent("tag_grid")
        .getStore()
        .load();
      this.netzkeGetComponent("script_grid")
        .getStore()
        .load();
      this.netzkeGetComponent("script_form").server.netzkeLoad({
        script_name: scriptName
      });
    }
  }
});
