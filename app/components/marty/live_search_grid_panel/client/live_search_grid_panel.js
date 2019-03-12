{
  initComponent: function () {
    var me = this;
    me.tbar = ['->',
      {
        name: 'live_search_text',
        xtype: 'textfield',
        enable_key_events: true,
        ref: '../live_search_field',
        empty_text: 'Search',
        listeners: {
          change: {
            fn: me.listenFn,
            buffer: 500,
          }
        }
      }
    ]
    this.callParent();
  },

  listenFn: function (obj, search_text) {
    var lg = this.ownerCt.ownerCt;
    lg.getStore().getProxy().extraParams.live_search = search_text;
    lg.getStore().load();
  }
}
