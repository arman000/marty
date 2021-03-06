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
  },

  listenFn(obj, searchText) {
    const lg = this.ownerCt.ownerCt;
    lg.getStore().getProxy().extraParams.live_search = searchText;
    lg.getStore().load();
  }
});
