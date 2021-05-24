({
  initComponent() {
    this.listeners = {
      drop: {
        element: "el",
        fn: "drop"
      },

      dragstart: {
        element: "el",
        fn: "addDropZone"
      },
      dragenter: {
        element: "el",
        fn: "addDropZone"
      },

      dragover: {
        element: "el",
        fn: "addDropZone"
      },

      dragleave: {
        element: "el",
        fn: "removeDropZone"
      },

      dragexit: {
        element: "el",
        fn: "removeDropZone"
      }
    };

    this.callParent();
  },

  noop(e) {
    e.stopEvent();
  },

  addDropZone(e) {
    if (
      !e.browserEvent.dataTransfer ||
      Ext.Array.from(e.browserEvent.dataTransfer.types).indexOf("Files") === -1
    ) {
      return;
    }

    e.stopEvent();
    this.addCls("drag-over");
  },

  removeDropZone(e) {
    let el = e.getTarget();
    const thisEl = this.getEl();

    e.stopEvent();

    if (el === thisEl.dom) {
      this.removeCls("drag-over");
      return;
    }

    while (el !== thisEl.dom && el && el.parentNode) {
      el = el.parentNode;
    }

    if (el !== thisEl.dom) {
      this.removeCls("drag-over");
    }
  },

  uploadFiles(files) {
    const me = this;

    if (files.length != 1 || !files[0].name.toLowerCase().endsWith(".zip"))
      return this.netzkeNotify("Please upload a single .zip file");

    const file = files[0];
    const reader = new FileReader();

    reader.onloadend = function(e) {
      me.server.uploadZip(file.name, e.target.result);
    };
    reader.readAsDataURL(file);
  },

  drop(e) {
    e.stopEvent();
    this.performDrop(Array.from(e.browserEvent.dataTransfer.files));
  },

  performDrop(files) {
    this.uploadFiles(files);
    this.removeCls("drag-over");
  }
});
