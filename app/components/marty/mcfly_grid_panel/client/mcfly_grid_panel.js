({
  initComponent() {
    this.callParent();

    // dup is a non standard button, so we have to explicitly manage
    // its clickability
    this.getSelectionModel().on(
      "selectionchange",
      function(selModel) {
        this.actions.dupInForm &&
          this.actions.dupInForm.setDisabled(
            !selModel.hasSelection() || !this.permissions.create
          );
      },
      this
    );
  },
  // copied from basepack grid's onEditInForm
  netzkeOnDupInForm() {
    const selModel = this.getSelectionModel();
    const recordId = selModel.getSelection()[0].getId();
    this.netzkeLoadComponent("edit_window", {
      title: "Duplicate in Form",
      serverConfig: {
        record_id: recordId
      },
      callback(w) {
        w.show();
        const form = w.items.first();
        form.baseParams = {
          dup: true
        };
        w.on(
          "close",
          function() {
            if (w.closeRes === "ok") {
              this.store.load();
            }
          },
          this
        );
      },
      scope: this
    });
  }
});
