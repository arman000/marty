({
  showDetail(details, title) {
    this.hideLoadMask();
    Ext.create("Ext.Window", {
      height: 400,
      minWidth: 400,
      maxWidth: 1200,
      autoWidth: true,
      modal: true,
      autoScroll: true,
      html: details,
      title: title || "Details"
    }).show();
  },

  showLoadMask(msg) {
    this.maskCmp = new Ext.LoadMask({
      msg: msg || "Loading...",
      target: this
    });
    this.maskCmp.show();
  },

  hideLoadMask() {
    if (this.maskCmp) {
      this.maskCmp.hide();
    }
  },

  netzkeOnNewPosting(_params) {
    this.netzkeLoadComponent("new_posting_window", {
      callback(w) {
        w.show();
      }
    });
  },

  netzkeOnSelectPosting(_params) {
    this.netzkeLoadComponent("posting_window", {
      callback(w) {
        w.show();
      }
    });
  },

  netzkeOnReload(_params) {
    window.location.reload();
  },

  netzkeOnLoadSeed(_params) {
    this.server.loadSeed({});
  },

  netzkeOnSelectNow(_params) {
    this.server.selectPosting({});
  },

  netzkeOnReloadScripts(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Reload Scripts",
      msg: "Enter RELOAD and press OK to force a reload of all scripts",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        btn == "ok" && value == "RELOAD" && me.server.reloadScripts({});
      }
    });
  },

  netzkeOnBgStop(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Stop Delayed Jobs",
      msg: "Enter STOP and press OK to force a stop of delayed_job",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        if (btn == "ok" && value == "STOP") {
          me.showLoadMask("Stopping delayed job...");
          me.server.bgStop({});
        }
      }
    });
  },

  netzkeOnBgRestart(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Restart Delayed Jobs",
      msg: "Enter RESTART and press OK to force a restart of delayed_job",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        if (btn == "ok" && value == "RESTART") {
          me.showLoadMask("Restarting delayed job...");
          me.server.bgRestart({});
        }
      }
    });
  },

  netzkeOnBgStatus() {
    this.showLoadMask("Checking delayed job status...");
    this.server.bgStatus({});
  },

  netzkeOnLogCleanup(_params) {
    const me = this;
    Ext.Msg.show({
      title: "Log Cleanup",
      msg: "Enter number of days to keep",
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn(btn, value) {
        btn == "ok" && me.server.logCleanup(value);
      }
    });
  }
});
