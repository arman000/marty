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

  setLineError: function (idx) {

    idx -= 1;
    var editor = this.getForm().findField('body').editor;

    if (idx > -1) {
      var line = editor.getLine(idx)
      editor.markText({
        line: idx,
        ch: 0
      }, {
        line: idx,
        ch: line.length
      }, {
        className: "errorline"
      });
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
