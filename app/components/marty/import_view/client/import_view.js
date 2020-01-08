({
  initComponent() {
    const me = this;
    me.callParent();
    // const form = me.getForm();

    const window = this.netzkeGetParentComponent();
    const parent_view = window.netzkeGetParentComponent();

    this.serverConfig.parent_id =
      parent_view.serverConfig.parent_id || parent_view.serverConfig.selected;

    // const textname = form.findField("import_data");
    const importbutton = me.actions["apply"].items[0];

    importbutton.on("click", function(_t, _e, _ops) {
      me.netzkeGetComponent("result").updateBodyHtml("");
    });
  },

  setResult(html) {
    const result = this.netzkeGetComponent("result");
    result.updateBodyHtml(html);

    const window = this.netzkeGetParentComponent();
    const parent_view = window.netzkeGetParentComponent();

    if (parent_view && parent_view.reload) {
      parent_view.reload();
    }
  }
});
