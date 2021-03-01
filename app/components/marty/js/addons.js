({
  // FIXME: move to netzke
  netzkeShowMessageBox(
    title,
    msg,
    additionalAttrs = {},
    replaceNewlinesWithBr = true
  ) {
    const message = replaceNewlinesWithBr
      ? msg.replace(/(?:\r\n|\r|\n)/g, "<br>")
      : msg;

    Ext.MessageBox.show(
      Object.assign(
        {
          title,
          msg: message,
          buttons: Ext.Msg.OK
        },
        additionalAttrs
      )
    );
  }
});
