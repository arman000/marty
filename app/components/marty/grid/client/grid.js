({
  getComponent(name) {
    return Ext.getCmp(name);
  },

  findComponent(name) {
    return Ext.ComponentQuery.query(`[name=${name}]`)[0];
  },

  setDisableComponentActions(prefix, flag) {
    for (const key in this.actions) {
      if (key.substring(0, prefix.length) == prefix) {
        this.actions[key].setDisabled(flag);
      }
    }
  },

  childReloadMs: 500,

  reloadChildren(selModel) {
    const children = this.serverConfig.child_components || [];
    const hasSel = selModel.hasSelection();

    let rid = null;
    if (hasSel) {
      if (selModel.type == "spreadsheet") {
        const cell = selModel.getSelected().startCell;
        rid = cell && cell.record.getId();
      }
      if (!rid) {
        const selected = selModel.getSelection()[0];
        rid = selected && selected.getId();
      }
    }

    this.serverConfig.selected = rid;
    this.setDisableComponentActions("do", !hasSel);

    for (const child of children) {
      const comp = this.findComponent(child);
      if (comp) {
        comp.serverConfig.parent_id = rid;
        if (comp.setDisableComponentActions) {
          comp.setDisableComponentActions("parent", !hasSel);
        }
        if (comp.reload) comp.reload();
      }
    }
  },
  initComponent() {
    this.dockedItems = this.dockedItems || [];
    if (this.paging == "pagination") {
      this.dockedItems.push({
        xtype: "pagingtoolbar",
        dock: "bottom",
        layout: {
          overflowHandler: "Menu"
        },
        listeners: {
          beforechange: this.disableDirtyPageWarning
            ? {}
            : {
                fn: this.netzkeBeforePageChange,
                scope: this
              }
        },
        store: this.store,
        items: this.bbar && ["-"].concat(this.bbar)
      });
    } else if (this.bbar) {
      this.dockedItems.push({
        xtype: "toolbar",
        dock: "bottom",
        layout: {
          overflowHandler: "Menu"
        },
        items: this.bbar
      });
    }

    const reloadChildrenDebouncer = new Ext.util.DelayedTask(
      this.reloadChildren
    );

    this.listeners = {
      selectionchange: (selModel) => {
        reloadChildrenDebouncer.delay(this.childReloadMs, null, this, [
          selModel
        ]);
      }
    };

    // block creation of toolbars in parent
    delete this.bbar;
    const paging = this.paging;
    if (paging != "buffered") {
      this.paging = false;
    }
    this.callParent();
    this.paging = paging;

    const me = this;
    const store = me.getStore();
    const linked = me.serverConfig.linked_components || [];
    for (const event of ["update", "netzkerefresh"]) {
      store.on(
        event,
        function() {
          for (const link of linked) {
            const comp = me.findComponent(link);
            if (comp && comp.reload) {
              comp.reload();
            }
          }
        },
        this
      );
    }
  },

  onSelectionChange(f) {
    const me = this;
    me.getSelectionModel().on("selectionchange", f);
  },

  netzkeSetActionEvents() {
    this.getSelectionModel().on(
      "selectionchange",
      function(selModel, selected) {
        if (this.actions.delete)
          this.actions.delete.setDisabled(selected.length == 0);

        if (this.actions.edit) {
          let disabled = false;
          Ext.each(selected, (r) => {
            if (r.isNew) {
              disabled = true;
              return false;
            }
          });

          this.actions.edit.setDisabled(selected.length == 0 || disabled);

          if (!this.multiEdit && selected.length > 1) {
            this.actions.edit.setDisabled(true);
          }
        }

        if (this.actions.editInForm) {
          this.actions.editInForm.setDisabled(selected.length == 0);

          if (!this.multiEdit && selected.length > 1) {
            this.actions.editInForm.setDisabled(true);
          }
        }
      },
      this
    );
  },

  // override netzkeReloadStore to allow option passthrough
  // reference: http://api.netzke.org/client/files/doc_client_netzke-basepack_javascripts_grid_event_handlers.js.html
  netzkeReloadStore(opts = {}) {
    const store = this.getStore();

    // HACK to work around buffered store's buggy reload()
    if (!store.lastRequestStart) {
      store.load(opts);
    } else store.reload(opts);
  },

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
  },

  // always reset store to first page on reload
  // to avoid load bug when moving from a higher page count
  // to a grid with a lower page count
  reload(opts = { start: 0 }) {
    this.netzkeReloadStore(opts);
  },

  reloadAll() {
    const me = this;
    const children = me.serverConfig.child_components || [];
    this.store.reload();
    for (const child of children) {
      const comp = me.findComponent(child);
      if (comp && comp.reload) {
        comp.reload();
      }
    }
  },

  clearFilters() {
    this.filters.clearFilters();
  },

  netzkeGridSelectedDefaultAction(endpoint, confirmation) {
    console.log(`
      netzkeGridSelectedDefaultAction is deprecated.
      Please use netzkeCallEndpoint instead.
    `);

    const selected = this.getSelectionModel()
      .getSelection()
      .map((r) => r.id);

    if (confirmation) {
      Ext.Msg.confirm(
        confirmation,
        Ext.String.format("Are you sure?"),
        (btn, _value, _cfg) => {
          if (btn == "yes") {
            this.server[endpoint](selected, () => {
              this.unmask();
            });
          }
        }
      );
    } else {
      this.server[endpoint](selected, () => {
        this.unmask();
      });
    }
  },

  // FIXME: move to netzke
  netzkeCallEndpoint(action) {
    const selected = this.getSelectionModel()
      .getSelection()
      .map((r) => r.id);
    const endpointName = action.endpointName || action.name;

    const camelCasedEndpointName = endpointName.replace(/_([a-z])/g, (g) =>
      g[1].toUpperCase()
    );

    const requireConfirmation =
      action.requireConfirmation || action.confirmationMessage;

    const handlerFunction = this.server[camelCasedEndpointName];

    if (!requireConfirmation) {
      return handlerFunction(selected, () => {
        this.unmask();
      });
    }

    const confirmationTitle = action.confirmationTitle || action.name;
    const confirmationMessage = action.confirmationMessage || "Are you sure?";
    const inProgressMessage = action.inProgressMessage || "In progress...";

    return Ext.Msg.confirm(
      confirmationTitle,
      Ext.String.format(confirmationMessage),
      (btn, _value, _cfg) => {
        if (btn !== "yes") {
          return null;
        }
        this.mask(inProgressMessage);
        return handlerFunction(selected, () => {
          this.unmask();
        });
      }
    );
  }
});
