{
  setActionModes: function (a) {
    this.actions.apply.setDisabled(!a["save"]);
    // style input field text based on whether it is editable
    this.getForm().findField('body').editor.setOption(
      "readOnly", !a["save"]);
  },

  getScriptId: function () {
    return this.getForm().findField('id').getValue();
  },

  setLineError: function (line) {
    console.log(this);
    line -= 1;
    var editor = this.getForm().findField('body').editor;
    if (editor.oldline) {
      editor.removeLineClass(line, "background", "errorline")
    }

    if (line > -1) {
      editor.addLineClass(line, "background", "errorline");
    }
    editor.refresh();
  },

  refreshParent: function (script_name) {
    this.netzkeGetParentComponent().scriptRefresh(script_name);
  },

  netzkeOnDoPrint: function (params) {
    this.server.doPrint(this.getScriptId());
  },

  getReport: function (report_path) {
    window.location = report_path;
  }
}
