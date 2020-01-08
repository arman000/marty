Ext.override(Ext.ux.StatusBar, {
  hideBusy() {
    return this.setStatus({
      text: this.defaultText,
      icon_cls: this.defaultIconCls
    });
  }
});
