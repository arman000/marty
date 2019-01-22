{
  getComponent: function (name) {
    return Ext.getCmp(name);
  },

  findComponent: function (name) {
    return Ext.ComponentQuery.query(`[name=${name}]`)[0];
  },

  setDisableComponentActions: function (prefix, flag) {
    for (var key in this.actions) {
      if (key.substring(0, prefix.length) == prefix) {
        this.actions[key].setDisabled(flag);
      }
    }
  },

  initComponent: function () {
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
      function (m) {
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
      store.on(event, function () {
        for (var link of linked) {
          var comp = me.findComponent(link);
          if (comp && comp.reload) {
            comp.reload()
          }
        }
      }, this);
    }
  },

  onSelectionChange: function (f) {
    var me = this;
    me.getSelectionModel().on('selectionchange', f);
  },

  doViewInForm: function (record) {
    this.netzkeLoadComponent("view_window", {
      serverConfig: {
        record_id: record.id
      },
      callback: function (w) {
        w.show();
        w.on('close', function () {
          if (w.closeRes === "ok") {
            this.netzkeReloadStore();
          }
        }, this);
      }
    });
  },

  reload: function (opts = {}) {
    this.netzkeReloadStore(opts);
  },

  reloadAll: function () {
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

  clearFilters: function () {
    this.filters.clearFilters();
  },
}