({
  setActionModes(a) {
    this.actions.apply.setDisabled(!a["save"]);
    // style input field text based on whether it is editable
    this.getForm()
      .findField("body")
      .editor.setOption("readOnly", !a["save"]);
  },

  getScriptId() {
    return this.getForm()
      .findField("id")
      .getValue();
  },

  setLineError(idx) {
    idx -= 1;
    const editor = this.getForm().findField("body").editor;

    if (idx > -1) {
      const line = editor.getLine(idx);
      editor.markText(
        {
          line: idx,
          ch: 0
        },
        {
          line: idx,
          ch: line.length
        },
        {
          className: "errorline"
        }
      );
    }
    editor.refresh();
  },

  refreshParent(script_name) {
    this.netzkeGetParentComponent().scriptRefresh(script_name);
  },

  netzkeOnDoPrint(_params) {
    this.server.doPrint(this.getScriptId());
  },

  getReport(report_path) {
    window.location = report_path;
  }
});
