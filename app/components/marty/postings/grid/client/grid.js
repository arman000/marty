({
  initComponent() {
    this.callParent();

    this.getSelectionModel().on(
      "selectionchange",
      function(selModel) {
        this.actions.detail &&
          this.actions.detail.setDisabled(!selModel.hasSelection());
      },
      this
    );
  },

  detail() {
    const recordId = this.getSelectionModel()
      .getSelection()[0]
      .getId();
    this.server.detail({
      record_id: recordId
    });
  },

  netzkeShowDetail(details) {
    Ext.create("Ext.Window", {
      height: 150,
      minWidth: 250,
      autoWidth: true,
      modal: true,
      autoScroll: true,
      html: details,
      title: "Posting Details"
    }).show();
  },

  netzkeOnDelete() {
    const records = [];
    const me = this;
    me.getSelectionModel().selected.each(function(r) {
      records.push(r.getId());
    }, me);

    // find the root component (main application)
    let mainApp = me;
    while (1) {
      const p = mainApp.netzkeGetParentComponent();
      if (!p) {
        break;
      }
      mainApp = p;
    }

    // assumes mainApp has serverSelectPosting method
    mainApp.server.selectPosting(records);
  }
});
