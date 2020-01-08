({
  initComponent() {
    const me = this;
    me.tbar = [
      "->",
      {
        name: "live_search_text",
        xtype: "textfield",
        enable_key_events: true,
        ref: "../live_search_field",
        empty_text: "Search",
        listeners: {
          change: {
            fn: me.listenFn,
            buffer: 500
          }
        }
      }
    ];
    this.callParent();
    this.getSelectionModel().on(
      "selectionchange",
      function(selModel) {
        this.actions.download &&
          this.actions.download.setDisabled(!selModel.hasSelection());
      },
      this
    );
    this.getView().getRowClass = this.defaultGetRowClass;
  },
  defaultGetRowClass(record, _index, _rowParams, _ds) {
    const status = record.get("status");
    if (status === false) return "red-row";
    if (status === true) return "green-row";
    return "orange-row";
  },

  listenFn(obj, search_text) {
    const lg = this.ownerCt.ownerCt;
    lg.getStore().getProxy().extraParams.live_search = search_text;
    lg.getStore().load();
  },

  netzkeOnDownload() {
    const jid = this.getSelectionModel()
      .getSelection()[0]
      .getId();
    // FIXME: seems pretty hacky
    window.location = this.jobPath(jid);
  },

  netzkeOnRefresh() {
    this.store.load();
  },

  netzkeOnClear(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Clear All Jobs",
      msg: "Enter CLEAR and press OK to clear all previous jobs",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        btn == "ok" && value == "CLEAR" && me.server.clear({});
      }
    });
  },

  // Updates model's `expanded` column if it's present.
  // Since promises don't have such column, we don't need to send that
  // extra request for every node expand event.
  netzkeOnNodeStateChange() {
    return;
  },

  netzkeOnCancelJob(_params) {
    const me = this;
    const sel = this.getSelectionModel().getSelection();
    if (sel.length != 1) {
      return this.netzkeNotify("select one job to cancel");
    }
    Ext.Msg.show({
      title: "Cancel this Job?",
      msg: "Enter CANCEL and press OK to cancel the job",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        btn == "ok" && value == "CANCEL" && me.server.cancelJob(sel[0].getId());
      }
    });
  }
});
