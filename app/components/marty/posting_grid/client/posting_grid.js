{
  initComponent: function () {
    this.callParent();

    this.getSelectionModel().on('selectionchange', function (selModel) {
      this.actions.detail &&
        this.actions.detail.setDisabled(!selModel.hasSelection());
    }, this);
  },

  detail: function () {
    record_id = this.getSelectionModel().getSelection()[0].getId();
    this.server.detail({
      record_id: record_id
    });
  },

  netzkeShowDetail: function (details) {
    Ext.create('Ext.Window', {
      height: 150,
      minWidth: 250,
      autoWidth: true,
      modal: true,
      autoScroll: true,
      html: details,
      title: "Posting Details"
    }).show();
  },

  netzkeOnDelete: function () {
    var records = [];
    var me = this;
    me.getSelectionModel().selected.each(function (r) {
      records.push(r.getId());
    }, me);

    // find the root component (main application)
    var main_app = me;
    while (1) {
      var p = main_app.netzkeGetParentComponent();
      if (!p) {
        break;
      }
      main_app = p;
    }

    // assumes main_app has serverSelectPosting method
    main_app.server.selectPosting(records);
  }
}
