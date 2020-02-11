({
  doViewInForm(record) {
    this.netzkeLoadComponent("view_window", {
      serverConfig: {
        record_id: record.id
      },
      callback(w) {
        w.show();
        w.on(
          "close",
          function() {
            if (w.closeRes === "ok") {
              this.netzkeReloadStore();
            }
          },
          this
        );
      }
    });
  }
});
