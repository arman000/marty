({
  initComponent() {
    this.callParent();
    this.getView().addElListener("keydown", (e) => {
      if (e.keyCode === e.ESC) {
        this.getSelectionModel().deselectAll();
      }
    });
  }
});
