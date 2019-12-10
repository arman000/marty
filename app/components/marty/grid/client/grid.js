{
  getComponent(name) {
    return Ext.getCmp(name);
  },

  findComponent(name) {
    return Ext.ComponentQuery.query(`[name=${name}]`)[0];
  },

  setDisableComponentActions(prefix, flag) {
    for (var key in this.actions) {
      if (key.substring(0, prefix.length) == prefix) {
        this.actions[key].setDisabled(flag);
      }
    }
  },

  initComponent() {
    this.dockedItems = this.dockedItems || [];
    if (this.paging == 'pagination') {
      this.dockedItems.push({
        xtype: 'pagingtoolbar',
        dock: 'bottom',
        layout: {
          overflowHandler: 'Menu'
        },
        listeners: {
          'beforechange': this.disableDirtyPageWarning ? {} : {
            fn: this.netzkeBeforePageChange,
            scope: this
          }
        },
        store: this.store,
        items: this.bbar && ["-"].concat(this.bbar)
      });
    } else if (this.bbar) {
      this.dockedItems.push({
        xtype: 'toolbar',
        dock: 'bottom',
        layout: {
          overflowHandler: 'Menu'
        },
        items: this.bbar
      });
    }

    // block creation of toolbars in parent
    delete this.bbar;
    var paging = this.paging
    if (paging != 'buffered') {
      this.paging = false;
    }
    this.callParent();
    this.paging = paging

    var me = this;

    var children = me.serverConfig.child_components || [];
    me.onSelectionChange(
      function(m) {
        var has_sel = m.hasSelection();

        var rid = null;
        if (has_sel) {
          if (m.type == 'spreadsheet') {
            var cell = m.getSelected().startCell;
            rid = cell && cell.record.getId();
          }
          if (!rid) {
            selected = m.getSelection()[0];
            rid = selected && selected.getId();
          }
        }

        me.serverConfig.selected = rid;
        me.setDisableComponentActions('do', !has_sel);

        for (var child of children) {
          var comp = me.findComponent(child)
          if (comp) {
            comp.serverConfig.parent_id = rid;
            if (comp.setDisableComponentActions) {
              comp.setDisableComponentActions('parent', !has_sel);
            }
            if (comp.reload) {
              comp.reload()
            }
          }
        }
      });

    var store = me.getStore();
    var linked = me.serverConfig.linked_components || [];
    for (var event of ['update', 'netzkerefresh']) {
      store.on(event, function() {
        for (var link of linked) {
          var comp = me.findComponent(link);
          if (comp && comp.reload) {
            comp.reload()
          }
        }
      }, this);
    }
  },

  onSelectionChange(f) {
    var me = this;
    me.getSelectionModel().on('selectionchange', f);
  },

  // override netzkeReloadStore to allow option passthrough
  // reference: http://api.netzke.org/client/files/doc_client_netzke-basepack_javascripts_grid_event_handlers.js.html
  netzkeReloadStore(opts = {}) {
    var store = this.getStore();

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
      callback: function(w) {
        w.show();
        w.on('close', function() {
          if (w.closeRes === "ok") {
            this.netzkeReloadStore();
          }
        }, this);
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
    var me = this;
    var children = me.serverConfig.child_components || [];
    this.store.reload();
    for (child of children) {
      var comp = me.findComponent(child);
      if (comp && comp.reload) {
        comp.reload()
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

    var selected = this.getSelectionModel().getSelection().map((r) => r.id)

    if (confirmation) {
      Ext.Msg.confirm(
        confirmation,
        Ext.String.format('Are you sure?'),
        (btn, value, cfg) => {
          if (btn == "yes") {
            this.server[endpoint](selected, () => { this.unmask() })
          }
        }
      );
    } else {
      this.server[endpoint](selected, () => { this.unmask() })
    }
  },

  // FIXME: move to netzke
  netzkeCallEndpoint(action) {
    const selected = this.getSelectionModel().getSelection().map((r) => r.id)
    const endpointName = action.endpointName || action.name;

    const camelCasedEndpointName = endpointName.replace(
      /_([a-z])/g,
      (g) => g[1].toUpperCase()
    );

    const requireConfirmation = action.requireConfirmation || action.confirmationMessage;

    const handlerFunction = this.server[camelCasedEndpointName];

    if (!requireConfirmation) {
      return handlerFunction(selected, () => { this.unmask()});
    };

    const confirmationTitle = action.confirmationTitle || action.name;
    const confirmationMessage = action.confirmationMessage || 'Are you sure?';
    const inProgressMessage = action.inProgressMessage || 'In progress...';

    return Ext.Msg.confirm(
      confirmationTitle,
      Ext.String.format(confirmationMessage),
      (btn, value, cfg) => {
        if (btn !== "yes") { return null; };
        this.mask(inProgressMessage);
        return handlerFunction(selected, () => { this.unmask()});
      }
    );
  },
}
