{
  initComponent: function () {
    var me = this;
    me.callParent();
    var form = me.getForm();

    var window = this.netzkeGetParentComponent();
    var parent_view = window.netzkeGetParentComponent();

    this.serverConfig.parent_id = parent_view.serverConfig.parent_id ||
      parent_view.serverConfig.selected;

    var textname = form.findField('import_data');
    var importbutton = me.actions["apply"].items[0];

    importbutton.on('click', function (t, e, ops) {
      me.netzkeGetComponent('result').updateBodyHtml('');
    });
  },

  setResult: function (html) {
    var result = this.netzkeGetComponent('result');
    result.updateBodyHtml(html);

    var window = this.netzkeGetParentComponent();
    var parent_view = window.netzkeGetParentComponent();

    if (parent_view && parent_view.reload) {
      parent_view.reload()
    }
  }
}
