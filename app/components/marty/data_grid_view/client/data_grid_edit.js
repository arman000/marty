({
  createStoreAndColumns(data, hdim, vdim, hcol, vcol, extraAttrs) {
    const fields = [];
    const columns = [];

    for (let i = 0; i < data[0].length; i++) {
      fields.push("a" + i);
      columns.push({
        dataIndex: "a" + i,
        text: i,
        sortable: false,
        editor: "textfield",
        renderer(value, meta) {
          const hlen = hdim.length,
            vlen = vdim.length,
            row = meta.rowIndex,
            col = meta.column.fullColumnIndex;

          if (extraAttrs[row][col]) {
            meta.tdStyle = extraAttrs[row][col][0];
            meta.tdAttr = Ext.String.format(
              'data-qtip="{0}"',
              extraAttrs[row][col][1]
            );
          }

          const valuesInRow = Object.keys(meta.record.data).filter((row) =>
            row.startsWith("a")
          ).length;

          // Make comments column non editable for H rows
          if (col === valuesInRow - 1) {
            meta.tdAttr = Ext.String.format('data-qtip="{0}"', "Comments");
            if (row === hlen - 1) {
              return "Comments:";
            }
          }

          if (row < hlen && col >= vlen) {
            meta.tdStyle = hcol[row];
            meta.tdAttr = Ext.String.format('data-qtip="{0}"', hdim[row]);
          }

          if (col < vlen && row >= hlen) {
            meta.tdStyle = vcol[col];
            meta.tdAttr = Ext.String.format('data-qtip="{0}"', vdim[col]);
          }

          return value;
        },
        autoSizeColumn: true
      });
    }

    const thestore = Ext.create("Ext.data.ArrayStore", {
      fields,
      data
    });

    return [columns, thestore];
  },

  editGrid(recordId, hdim, vdim, data, titleStr, permission) {
    const colors = [
      "background-color: #FFA1A1;",
      "background-color: #FF9D5C;",
      "background-color: #A1A1FF;",
      "background-color: #FFFFA1;",
      "background-color: #A1FFFF;",
      "background-color: #FFA1FF;",
      "background-color: #A1A187;",
      "background-color: #D1FFD1;",
      "background-color: #FFD1D1;",
      "background-color: #FF9D7C;",
      "background-color: #D1D1FF;",
      "background-color: #FFFFD1;",
      "background-color: #D1FFFF;",
      "background-color: #FFD1FF;",
      "background-color: #D1D1B7;"
    ];
    const hcol = [];
    const vcol = [];

    let me = this;
    // setup colors for hdims
    for (let i = 0; i < hdim.length; i++) hcol[i] = colors.pop();
    // setup colors for vdims
    for (let i = 0; i < vdim.length; i++) vcol[i] = colors.pop();

    const createArray = function(length) {
      const arr = new Array(length || 0);
      let i = length;

      if (arguments.length > 1) {
        const args = Array.prototype.slice.call(arguments, 1);
        while (i--) arr[length - 1 - i] = createArray.apply(this, args);
      }

      return arr;
    };

    const extraAttrs = createArray(data.length, data[0].length);

    const [columns, thestore] = this.createStoreAndColumns(
      data,
      hdim,
      vdim,
      hcol,
      vcol,
      extraAttrs
    );

    let dirty = false;
    const setDirty = function() {
      dirty = true;
    };
    const getDirty = function() {
      return dirty;
    };

    me = this;

    const dataUpdate = function(grid, modFunc) {
      const storeData = grid.getStore().data.items;
      const modData = [];
      modFunc(storeData, modData);
      const extraAttrs = createArray(modData.length, modData[0].length);
      const [newcolumns, newstore] = me.createStoreAndColumns(
        modData,
        hdim,
        vdim,
        hcol,
        vcol,
        extraAttrs
      );
      grid.reconfigure(newstore, newcolumns);

      Ext.each(grid.getColumns(), function(column) {
        column.autoSize();
      });
      setDirty();
    };

    const insertRow = function(inData, outData, rowIdx, up) {
      const width = inData[0].fields.length - 1;
      const newa = Array.apply(null, Array(width)).map(function() {
        return "";
      });
      const target = up ? rowIdx : rowIdx + 1;
      for (let i = 0; i <= inData.length; ++i) {
        if (i == target) {
          outData.push(newa);
        }
        if (i < inData.length) {
          const row = [];
          for (const [key, value] of Object.entries(inData[i].data)) {
            if (key != "id") row.push(value);
          }
          outData.push(row);
        }
      }
    };

    const insertCol = function(inData, outData, colIdx, left) {
      const target = left ? colIdx : colIdx + 1;
      const rowWidth = inData[0].fields.length;
      for (let i = 0; i < inData.length; ++i) {
        const row = [];
        let idx = 0;
        for (const [key, value] of Object.entries(inData[i].data)) {
          if (idx == target) row.push(null);
          if (key != "id") row.push(value);
          ++idx;
        }
        if (target == rowWidth) row.push(null);
        outData.push(row);
      }
    };

    const deleteRow = function(inData, outData, rowIdx) {
      for (let i = 0; i < inData.length; ++i) {
        if (i != rowIdx) {
          const row = [];
          for (const [key, value] of Object.entries(inData[i].data)) {
            if (key != "id") row.push(value);
          }
          outData.push(row);
        }
      }
    };

    const deleteCol = function(inData, outData, colIdx) {
      for (let i = 0; i < inData.length; ++i) {
        const row = [];
        let idx = 0;
        for (const [key, value] of Object.entries(inData[i].data)) {
          if (idx != colIdx && key != "id") row.push(value);
          ++idx;
        }
        outData.push(row);
      }
    };

    const lookupGrid = function() {
      return Ext.ComponentQuery.query("grid").find(function(v) {
        return v.name == "data_grid_edit_grid";
      });
    };

    const lookupWin = function() {
      return Ext.ComponentQuery.query("window").find(function(v) {
        return v.name == "data_grid_edit_window";
      });
    };

    const insertRowAboveAction = Ext.create("Ext.Action", {
      text: "Insert Row Above",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          insertRow(data, modData, widget.position.row, true);
        });
      }
    });

    const insertRowBelowAction = Ext.create("Ext.Action", {
      text: "Insert Row Below",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          insertRow(data, modData, widget.position.row, false);
        });
      }
    });

    const insertColLeftAction = Ext.create("Ext.Action", {
      text: "Insert Column Left",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          insertCol(data, modData, widget.position.col, true);
        });
      }
    });

    const insertColRightAction = Ext.create("Ext.Action", {
      text: "Insert Column Right",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          insertCol(data, modData, widget.position.col, false);
        });
      }
    });

    const deleteRowAction = Ext.create("Ext.Action", {
      text: "Delete Row",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          deleteRow(data, modData, widget.position.row);
        });
      }
    });

    const deleteColAction = Ext.create("Ext.Action", {
      text: "Delete Column",
      handler(widget, _event) {
        const grid = lookupGrid();
        dataUpdate(grid, function(data, modData) {
          deleteCol(data, modData, widget.position.col);
        });
      }
    });

    const itemContextMenu = Ext.create("Ext.menu.Menu", {
      items: [
        insertRowAboveAction,
        insertRowBelowAction,
        insertColLeftAction,
        insertColRightAction,
        deleteRowAction,
        deleteColAction
      ]
    });

    // Selection Models
    const spSel = Ext.create("Ext.grid.selection.SpreadsheetModel", {
      cellSelect: true,
      columnSelect: true,
      rowSelect: false,
      extensible: true,
      mode: "MULTI"
    });

    const getArea = (row, col) => {
      let a;

      const rowHdim = row < hdim.length,
        rowVdim = col < vdim.length;

      const valuesInRow = Object.keys(
        lookupGrid().store.data.items[0].data
      ).filter((row) => row.startsWith("a")).length;

      if (rowHdim && col == valuesInRow - 1) a = "h_row_comments_area";
      else if (!rowHdim && col == valuesInRow - 1) a = "comments_area";
      else if (rowHdim && rowVdim) a = "blank_area";
      else if (!rowHdim && !rowVdim) a = "data_area";
      else if (rowHdim && !rowVdim) a = "hdim_area";
      else a = "vdim_area";
      return a;
    };

    const canEdit = function(row, col) {
      const area = getArea(row, col);

      if (area == "blank_area") return false;
      if (area == "h_row_comments_area") return false;

      if (area == "data_area" || area == "comments_area") {
        return permission != "view";
      }

      if (area == "vdim_area" || area == "hdim_area")
        return permission == "edit_all";
    };

    // Plugins
    const cellEditor = Ext.create("Ext.grid.plugin.CellEditing", {
      clicksToEdit: 2,
      listeners: {
        beforeedit(editor, context, _eOpts) {
          if (!canEdit(context.rowIdx, context.colIdx)) return false;
        },
        afteredit() {
          setDirty();
        }
      }
    });

    const contextDisableFn = function(menu, label, x, y, fn) {
      const mi = menu.items.items.find(function(mi) {
        return mi.text == label;
      });
      if (fn(x, y)) mi.enable();
      else mi.disable();
    };

    // check to see if menu item should be enabled based on row, col
    const rowMenuCheck = function(row, col) {
      const area = getArea(row, col);
      if (vdim.length == 0) return false;
      return (
        (area == "vdim_area" ||
          area == "data_area" ||
          area == "comments_area") &&
        permission == "edit_all"
      );
    };

    const colMenuCheck = function(row, col) {
      const area = getArea(row, col);

      if (hdim.length == 0) return false;

      if (area == "comments_area" || area == "h_row_comments_area") {
        return false;
      }

      return (
        (area == "hdim_area" ||
          area == "data_area" ||
          area == "comments_area") &&
        permission == "edit_all"
      );
    };

    const insertColLeftCheck = function(row, col) {
      const area = getArea(row, col);
      if (hdim.length == 0) return false;

      return (
        (area == "hdim_area" ||
          area == "data_area" ||
          area == "comments_area" ||
          area == "h_row_comments_area") &&
        permission == "edit_all"
      );
    };

    const disableConds = [
      ["Insert Row Above", rowMenuCheck],
      ["Insert Row Below", rowMenuCheck],
      ["Delete Row", rowMenuCheck],
      ["Insert Column Left", insertColLeftCheck],
      ["Insert Column Right", colMenuCheck],
      ["Delete Column", colMenuCheck]
    ];

    Ext.define("DGEdit.grid.plugin.Clipboard", {
      override: "Ext.grid.plugin.Clipboard",
      beforepaste: Ext.emptyFn,
      mixins: ["Ext.mixin.Observable"],
      constructor(config) {
        const me = this;

        me.callParent([config]);
        me.mixins.observable.constructor.call(me);
      },
      privates: {
        onPaste(keyCode, event) {
          const me = this,
            sharedData = me.shared.data,
            source = me.getSource(),
            rowIdx = event.position.rowIdx,
            colIdx = event.position.colIdx;
          let i, n, s;
          if (!canEdit(rowIdx, colIdx)) {
            return;
          }
          if (me.fireEvent("beforepaste", keyCode, event, me.cmp) !== false) {
            if (source) {
              for (i = 0, n = source.length; i < n; ++i) {
                s = source[i];
                if (s === "system") {
                  // get the format used by the system clipboard.
                  s = me.getSystem();
                  me.pasteClipboardData(s);
                  break;
                } else if (sharedData && s in sharedData) {
                  me.doPaste(s, sharedData[s]);
                  break;
                }
              }
            }
          }
        }
      }
    });
    Ext.define("DGEditController", {
      extend: "Ext.app.ViewController",
      alias: "controller.dataGridEdit",
      onBeforePaste(_keyCode, _event, _grid) {
        return false;
      }
    });
    Ext.tip.Tip.prototype.minWidth = void 0;
    Ext.tip.QuickTipManager.init();

    const grid = {
      xtype: "grid",
      name: "data_grid_edit_grid",
      border: false,
      autoEncode: true,
      controller: "dataGridEdit",
      columns,
      scrollable: true,
      anchor: "100% 100%",
      forceFit: true,
      store: thestore,
      hideHeaders: true,
      columnLines: true,
      plugins: [
        cellEditor,
        {
          ptype: "clipboard",
          system: "raw"
          //            listeners: {
          //               beforepaste: 'onBeforePaste'
          //          }
        }
      ],
      selModel: spSel,
      listeners: {
        containercontextmenu(view, e) {
          e.preventDefault();
        },
        contextmenu(e, _element, _options) {
          e.preventDefault();
        },
        itemcontextmenu(view, record, item, index, e) {
          e.stopEvent();
          const items = itemContextMenu.items.items;
          const ctn = items.length;
          const y = e.position.colIdx;
          const x = e.position.rowIdx;
          for (let i = 0; i < ctn; ++i) {
            items[i].position = { col: y, row: x };
          }
          for (const [label, fn] of disableConds) {
            contextDisableFn(itemContextMenu, label, x, y, fn);
          }
          itemContextMenu.showAt(e.getXY());
        }
      }
    };
    const fbsave = {
      text: "Save",
      handler() {
        this.up("window").submit();
      }
    };
    const fbcancel = {
      text: "Cancel",
      handler() {
        this.up("window").close();
      }
    };
    const fbar = permission == "view" ? [fbcancel] : [fbsave, fbcancel];

    Ext.create("Ext.Window", {
      name: "data_grid_edit_window",
      height: "90%",
      width: "90%",
      x: 100,
      y: 100,
      autoWidth: true,
      modal: true,
      autoScroll: true,
      title: titleStr,
      layout: "anchor",
      items: grid,
      submit() {
        Ext.getBody()
          .mask("Saving data...")
          .setZIndex(99999)
          .setStyle("cursor", "wait");
        const grid = Ext.ComponentQuery.query("grid").find(function(v) {
          return v.name == "data_grid_edit_grid";
        });
        const server = me.server;

        if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
          const store = grid.getStore().data.items;
          const ret = [];

          for (let i = 0; i < store.length; ++i) {
            const row = {};

            let colIdx = 0;

            // or remove label fields we added in top left
            const colNull = i < hdim.length ? vdim.length : 0;

            for (const [key, value] of Object.entries(store[i].data)) {
              if (key != "id") {
                if (colIdx < colNull) row[key] = "";
                else row[key] = value;
              }
              // const col0_skip = false;
              colIdx++;
            }
            ret.push(row);
          }

          server.saveGrid({ record_id: recordId, data: ret }, function(res) {
            if (res) {
              if (res["errorMessage"]) {
                Ext.MessageBox.show({
                  title: "Error in data",
                  msg: "error: " + res["errorMessage"],
                  buttons: Ext.Msg.OK
                });
              } else if (res["problemArray"]) {
                Ext.MessageBox.show({
                  title: "Error in data",
                  msg:
                    "error: some entries failed constraint or data type check",
                  buttons: Ext.Msg.OK
                });
                for (const [type, x, y] of res["problemArray"]) {
                  const realX = vdim.length + x,
                    realY = hdim.length + y;
                  if (type == "constraint")
                    extraAttrs[realY][realX] = [
                      "background-color: #FF8181;",
                      "failed constraint check"
                    ];
                  else if (type == "type")
                    extraAttrs[realY][realX] = [
                      "background-color: #FFB181;",
                      "failed type check"
                    ];
                }
                grid.getView().refresh();
              }
            } else {
              const win = lookupWin();
              win.destroy();
            }
            Ext.getBody().unmask();
          });
        } else {
          Ext.getBody().unmask();
          Ext.MessageBox.show({
            title: "Nothing to Save",
            msg: "No changes made",
            buttons: Ext.Msg.OK
          });
        }
      },
      closeAction: "destroy",
      listeners: {
        beforeclose(win) {
          const grid = lookupGrid();
          if (win.closeMe) {
            win.closeMe = false;
            grid.destroy();
            return true;
          }
          if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
            Ext.MessageBox.show({
              title: "Discard Changes?",
              msg:
                "You are closing a window that has unsaved changes. Are you sure?",
              buttons: Ext.Msg.YESNO,
              icon: Ext.Msg.QUESTION,
              callback(btn) {
                if ("yes" === btn) {
                  win.closeMe = true;
                  win.close();
                }
              }
            });
            return false;
          }
          grid.destroy();
          return true;
        }
      },
      fbar
    }).show();

    const gridobj = Ext.ComponentQuery.query("grid").find(function(v) {
      return v.name == "data_grid_edit_grid";
    });

    Ext.each(gridobj.getColumns(), function(column) {
      column.autoSize();
      column.setWidth(column.getWidth() + 20);
    });
  }
});
