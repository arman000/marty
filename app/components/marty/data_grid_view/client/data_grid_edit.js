{
    editGrid:
    function(record_id, hdim, vdim, data, title_str) {
        var colors = [
            'background-color: #A1FFA1;',
            'background-color: #FFA1A1;',
            'background-color: #FF9D5C;',
            'background-color: #A1A1FF;',
            'background-color: #FFFFA1;',
            'background-color: #A1FFFF;',
            'background-color: #FFA1FF;',
            'background-color: #A1A197;',
            'background-color: #D1FFD1;',
            'background-color: #FFD1D1;',
            'background-color: #FF9D7C;',
            'background-color: #D1D1FF;',
            'background-color: #FFFFD1;',
            'background-color: #D1FFFF;',
            'background-color: #FFD1FF;',
            'background-color: #D1D1C7;',
        ];
        var hcol = [];
        var vcol = []
        var me = this;

        if (hdim.length == 0) {
            var vwid = vdim.length;
            var newa = Array.apply(null, Array(vwid+1)).map(function () { return ""; });
            data.unshift(newa);
        }
        if (vdim.length == 0) {
            for (var i=0; i < data.length; ++i) {
                data[i].unshift("");
            }
        }
        // setup colors and labels for hdims
        for (var i=0; i<hdim.length; i++)
        {
            hcol[i] = colors.pop()
            var idx = Math.max(0, vdim.length - 1);
            data[i][idx] = hdim[i];
        }

        // setup colors and labels for vdims
        for (var i=0; i<vdim.length; i++)
        {
            vcol[i] = colors.pop();

            var idx = Math.max(0, hdim.length - 1);
            cur = data[idx][i];
            if (cur)
                data[idx][i] = vdim[i] + ' / ' + cur;
            else
                data[idx][i] = vdim[i];
        }
//        debugger;
        var createStoreAndColumns =
            function(data) {
                var fields = [];
                var columns = [];
                for (var i=0; i< data[0].length; i++) {
                    fields.push("a" + i);
                    columns.push({dataIndex: "a" + i, text: i,
                                  sortable: false,
                                  editor: 'textfield',
                                  renderer: function(value, meta) {
                                      if(meta.rowIndex < hdim.length &&
                                         meta.column.fullColumnIndex > vdim.length)
                                      {
                                          meta.tdStyle = hcol[meta.rowIndex];
                                      }
                                      if (meta.column.fullColumnIndex <= vdim.length  &&
                                          meta.rowIndex >= hdim.length)
                                      {
                                          meta.tdStyle = vcol[meta.column.fullColumnIndex-1];
                                      }
                                      return value;
                                  },
                                  autoSizeColumn: true});
                }
                var thestore = Ext.create('Ext.data.ArrayStore', {
                    fields: fields,
                    data: data,
                });
                return [columns, thestore];
            };

        var columns, thestore;
        [columns, thestore] = createStoreAndColumns(data);

        var dirty = false;
        var setDirty = function() { dirty = true; }
        var getDirty = function() { return dirty; }

        var dataUpdate = function(grid, modFunc) {
            var store_data = grid.getStore().data.items;
            var newcolumns, newstore;
            var mod_data = [];
            modFunc(store_data, mod_data);
            [newcolumns, newstore] = createStoreAndColumns(mod_data);
            grid.reconfigure(newstore, newcolumns);
            Ext.each(grid.getColumns(), function(column) {
                column.autoSize();
                column.setWidth(column.getWidth()+20);
            });
            setDirty();
        }
        var insertRow = (vdim.length == 0) ? 
            function() {}
            :
            function(inData, outData, rowIdx, up) {
            var width = inData[0].fields.length -1
            var newa = Array.apply(null, Array(width)).map(function () { return ""; });
            var target = up ? rowIdx : rowIdx + 1;
            for (var i=0; i<= inData.length; ++i) {
                if (i == target) {
                    outData.push(newa);
                }
                if (i < inData.length) {
                    var row = [];
                    for (const [key, value] of Object.entries(inData[i].data)) {
                        if (key != 'id') row.push(value);
                    }
                    outData.push(row);
                }
            }
        }
        var insertCol = (hdim.length == 0) ?
            function() {}
            :
            function(inData, outData, colIdx, left) {
                
                var target = left ? colIdx - 1 : colIdx
                var row_width = inData[0].fields.length;
                for (var i=0; i< inData.length; ++i) {
                    var row = [];
                    var idx = 0;
                    for (const [key, value] of Object.entries(inData[i].data)) {
                        if (idx == target) row.push(null);
                        if (key != 'id') row.push(value);
                        ++idx;
                    }
                    if (target == row_width) row.push(null);
                    outData.push(row);
                }
            };
        var deleteRow = (vdim.length == 0) ?
            function() {}
            :
            function(inData, outData, rowIdx) {
            for (var i=0; i< inData.length; ++i) {
                if (i != rowIdx) {
                    var row = [];
                    for (const [key, value] of Object.entries(inData[i].data)) {
                        if (key != 'id')
                            row.push(value);
                    }
                    if (idx != rowIdx)
                        outData.push(row);
                }
            }
        }
        var deleteCol = (hdim.length == 0) ? 
            function() {}
            :
            function(inData, outData, colIdx) {
            for (var i=0; i< inData.length; ++i) {
                var row = [];
                var idx = 0;
                for (const [key, value] of Object.entries(inData[i].data)) {
                    if (idx != colIdx - 1 && key != 'id')
                        row.push(value);
                    ++idx;
                }
                outData.push(row);
            }
        }
        var insertRowAboveAction = Ext.create('Ext.Action', {
            text: 'Insert Row Above',
            handler: function(widget , event) {
                if (widget.position.row < Math.max(1, hdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                var gridx = Ext.ComponentQuery.query('grid');
                dataUpdate(grid, function(data, mod_data) {
                    insertRow(data, mod_data, widget.position.row, true);
                });
            }
        });
        var insertRowBelowAction = Ext.create('Ext.Action', {
            text: 'Insert Row Below',
            handler: function(widget , event) {
                if (widget.position.row < Math.max(1, hdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                dataUpdate(grid, function(data, mod_data) {
                    insertRow(data, mod_data, widget.position.row, false);
                });
            }
        });
        var insertColLeftAction = Ext.create('Ext.Action', {
            text: 'Insert Column Left',
            handler: function(widget , event) {
                if (widget.position.col-1 < Math.max(1, vdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                dataUpdate(grid, function(data, mod_data) {
                    insertCol(data, mod_data, widget.position.col, true);
                });
            }
        });
        var insertColRightAction = Ext.create('Ext.Action', {
            text: 'Insert Column Right',
            handler: function(widget , event) {
                if (widget.position.col-1 < Math.max(1, vdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                dataUpdate(grid, function(data, mod_data) {
                    insertCol(data, mod_data, widget.position.col, false);
                });
            }
        });
        var deleteRowAction = Ext.create('Ext.Action', {
            text: 'Delete Row',
            handler: function(widget , event) {
                if (widget.position.row < Math.max(1, hdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                dataUpdate(grid, function(data, mod_data) {
                    deleteRow(data, mod_data, widget.position.row);
                });
            }
        });
        var deleteColAction = Ext.create('Ext.Action', {
            text: 'Delete Column',
            handler: function(widget , event) {
                if (widget.position.col-1 < Math.max(1, vdim.length)) return;
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                dataUpdate(grid, function(data, mod_data) {
                    deleteCol(data, mod_data, widget.position.col);
                });
            }
        });
        var itemContextMenu = Ext.create('Ext.menu.Menu' , {
            items: [insertRowAboveAction, insertRowBelowAction, insertColLeftAction,
                    insertColRightAction, deleteRowAction, deleteColAction]});

        // Selection Models
        var spSel = Ext.create("Ext.grid.selection.SpreadsheetModel", {
            cellSelect: true,
            columnSelect: true,
            rowSelect: true,
            dragSelect: true,
            extensible: true,
            rowSelect: true,
            mode: "MULTI"
        });

        // Plugins
        var cellEditor = Ext.create("Ext.grid.plugin.CellEditing", {
            clicksToEdit: 2,
            listeners: {
                beforeedit: function(editor, context, eOpts) {
                    if ((context.colIdx <= vdim.length &&
                         context.rowIdx < hdim.length) ||
                        (context.rowIdx == 0 &&
                         hdim.length == 0) ||
                        (context.colIdx == 1 &&
                         vdim.length == 0)) {
                        return false;
                    }
                },
                afteredit: function() {
                    setDirty();
                },
            }
        });

        var grid = {
            xtype:       'grid',
            name:        'data_grid_edit_grid',
            border:      false,
            hideHeaders: false,
            autoEncode: true,
            columns:     columns,
            scrollable: true,
            anchor: '100% 100%',
            forceFit: true,
            store:       thestore,
            plugins: [cellEditor,
                      {
                          ptype: 'clipboard',
                          memory: 'raw',
                          source: ['html', 'raw', 'text'],
                          formats:  {
                              text: {
                                  get: 'getHtmlData',
                                  put: 'putHtmlData'
                              },
                              html: {
                                  get: 'getHtmlData',
                                  put: 'putHtmlData'
                              }
                          }
                      }],
            selModel: spSel,
            listeners: {
                containercontextmenu: function(view, e) {
                    e.preventDefault();
                },
                contextmenu: function(e, element, options) {
                    e.preventDefault();
                },
                itemcontextmenu: function(view, record, item, index, e) {
                    e.stopEvent();
                    var items = itemContextMenu.items.items;
                    var ctn    = items.length;
                    for (var i=0; i<ctn; ++i) {
                        items[i].position = {col: e.position.colIdx,
                                             row: e.position.rowIdx};
                    }

                    itemContextMenu.showAt(e.getXY());
                },

            }
        };
        Ext.create('Ext.Window', {
            name: 'data_grid_edit_window',
            height:        "90%",
            width:         "90%",
            x:             100,
            y:             100,
            autoWidth:     true,
            modal:         true,
            autoScroll:    true,
            title:         title_str,
            layout: 'anchor',
            items: grid,
            submit: function() {
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                var server = me.server;
                if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
                    var store = grid.getStore().data.items;
                    var ret = [];
                    for (var i=0; i < store.length; ++i) {
                        var row = {};
                        for (const [key, value] of Object.entries(store[i].data)) {
                            if (key != 'id') row[key] = value;
                        }
                        ret.push(row);
                    }
                    server.saveGrid({record_id: record_id, data: ret}, function(res) {
                        if (res) {
                            Ext.MessageBox.show({
                                title:'Error in data',
                                msg: 'error: ' + res,
                                buttons: Ext.Msg.OK
                            });
                        }
                        else
                        {
                            var win = grid = Ext.ComponentQuery.query('window').find(function(v) {
                                return v.name=='data_grid_edit_window'
                            });
                            win.doDestroy();
                        }
                    });
                }
                else
                {
                    Ext.MessageBox.show({
                        title:'Nothing to Save',
                        msg: 'No changes made',
                        buttons: Ext.Msg.OK
                    });
                }
            },
            closeAction: 'hide',
            fbar: [{
                text: 'Save',
                handler: function () {
                    this.up('window').submit();
                }},
                {
                text: 'Cancel',
                handler: function () {
                    var win = Ext.ComponentQuery.query('window').find(function(v) {
                        return v.name=='data_grid_edit_window'
                    });
                    var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                        return v.name=='data_grid_edit_grid'
                    });
                    if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
                        Ext.MessageBox.show({
                            title:'Discard Changes?',
                            msg: 'You are closing a window that has unsaved changes. Are you sure?',
                            buttons: Ext.Msg.YESNO,
                            icon: Ext.Msg.QUESTION,
                            fn: function(btn){
                                if (btn == "no"){
                                    //NO
                                }
                                if (btn == "yes"){
                                    win.doDestroy();
                                }
                            }
                        });
                    } else {
                        win.doDestroy();
                    }}}]
        }).show();
        var gridobj = Ext.ComponentQuery.query('grid').find(function(v) {
            return v.name=='data_grid_edit_grid'
        });
        Ext.each(gridobj.getColumns(), function(column) {
            column.autoSize();
            column.setWidth(column.getWidth()+20);
        });
    }
}
