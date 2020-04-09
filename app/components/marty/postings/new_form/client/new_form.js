({
  closeMe() {
    // assume we're embedded in a window
    this.netzkeGetParentComponent().close();
  },

  initComponent() {
    this.callParent();

    const postingType = this.getForm().findField("posting_type");
    const me = this;

    me.serverConfig.selected_posting_type = null;
    // For some reason initComponent gets called twice
    // So this workaround prevents from adding the listener second time
    if (this.hasPostingTypeChangeListener) {
      return;
    }

    postingType.on("change", function(self, record) {
      if (record instanceof Array) {
        record = record[0];
      }

      me.serverConfig.selected_posting_type = record;
      me.getComponent("summary_grid")
        .getStore()
        .load();
    });

    this.hasPostingTypeChangeListener = true;
  }
});
