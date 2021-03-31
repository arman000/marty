({
  netzkeOnCleanup(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Report History Cleanup",
      msg: "Enter number of days to keep",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        btn == "ok" && me.server.cleanup(value);
      }
    });
  }
});
