({
  initComponent() {
    const me = this;
    me.callParent();
    // const form = me.getForm();

    const window = this.netzkeGetParentComponent();
    const parentView = window.netzkeGetParentComponent();

    this.serverConfig.parent_id =
      parentView.serverConfig.parent_id || parentView.serverConfig.selected;

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
    const parentView = window.netzkeGetParentComponent();

    if (parentView && parentView.reload) {
      parentView.reload();
    }
  }
});
