{
  showDetail: function (details, title) {
    this.hideLoadmask();
    Ext.create('Ext.Window', {
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

  showLoadMask: function (msg) {
    this.maskCmp = new Ext.LoadMask({
      msg: msg || 'Loading...',
      target: this,
    });
    this.maskCmp.show();
  },

  hideLoadMask: function () {
    if (this.maskCmp) {
      this.maskCmp.hide();
    };
  },

  netzkeOnNewPosting: function (params) {
    this.netzkeLoadComponent("new_posting_window", {
      callback: function (w) {
        w.show();
      },
    });
  },

  netzkeOnSelectPosting: function (params) {
    this.netzkeLoadComponent("posting_window", {
      callback: function (w) {
        w.show();
      },
    });
  },

  netzkeOnReload: function (params) {
    window.location.reload();
  },

  netzkeOnLoadSeed: function (params) {
    this.server.loadSeed({});
  },

  netzkeOnSelectNow: function (params) {
    this.server.selectPosting({});
  },

  netzkeOnReloadScripts: function (params) {
    var me = this;
    Ext.Msg.show({
      title: 'Reload Scripts',
      msg: 'Enter RELOAD and press OK to force a reload of all scripts',
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn: function (btn, value) {
        btn == "ok" && value == "RELOAD" && me.server.reloadScripts({});
      }
    });
  },

  netzkeOnBgStop: function (params) {
    var me = this;
    Ext.Msg.show({
      title: 'Stop Delayed Jobs',
      msg: 'Enter STOP and press OK to force a stop of delayed_job',
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn: function (btn, value) {
        if (btn == "ok" && value == "STOP") {
          me.showLoadmask('Stopping delayed job...');
          me.server.bgStop({});
        }
      }
    });
  },

  netzkeOnBgRestart: function (params) {
    var me = this;
    Ext.Msg.show({
      title: 'Restart Delayed Jobs',
      msg: 'Enter RESTART and press OK to force a restart of delayed_job',
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn: function (btn, value) {
        if (btn == "ok" && value == "RESTART") {
          me.showLoadmask('Restarting delayed job...');
          me.server.bgRestart({});
        }
      }
    });
  },

  netzkeOnBgStatus: function () {
    this.showLoadmask('Checking delayed job status...');
    this.server.bgStatus({});
  },

  netzkeOnLogCleanup: function (params) {
    var me = this;
    Ext.Msg.show({
      title: 'Log Cleanup',
      msg: 'Enter number of days to keep',
      width: 375,
      buttons: Ext.Msg.OKCANCEL,
      prompt: true,
      fn: function (btn, value) {
        btn == "ok" && me.server.logCleanup(value);
      }
    });
  }
}
