{
    createStoreAndColumns:
    function(data, hdim, vdim, hcol, vcol) {
        var fields = [];
        var columns = [];
        for (var i=0; i< data[0].length; i++) {
            fields.push("a" + i);
            columns.push({dataIndex: "a" + i, text: i,
                          sortable: false,
                          editor: 'textfield',
                          renderer: function(value, meta) {
                              var hlen = Math.max(1, hdim.length),
                                  vlen = Math.max(1, vdim.length),
                                  row = meta.rowIndex,
                                  col = meta.column.fullColumnIndex - 1;
                              
                              if (row < hlen && col >= vlen)
                              {
                                  meta.tdStyle = hcol[row];
                                  meta.tdAttr = Ext.String.format('data-qtip="{0}"',
                                                                  hdim[row]);
                              }
                              if (col <= vlen && row >= hlen)
                              {
                                  meta.tdStyle = vcol[col];
                                  meta.tdAttr = Ext.String.format('data-qtip="{0}"',
                                                                  vdim[col]);
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
    },
    editGrid:
    function(record_id, hdim, vdim, data, title_str, permission) {
        var colors = [

            'background-color: #FFA1A1;',
            'background-color: #FF9D5C;',
            'background-color: #A1A1FF;',
            'background-color: #FFFFA1;',
            'background-color: #A1FFFF;',
            'background-color: #FFA1FF;',
            'background-color: #A1A187;',
            'background-color: #D1FFD1;',
            'background-color: #FFD1D1;',
            'background-color: #FF9D7C;',
            'background-color: #D1D1FF;',
            'background-color: #FFFFD1;',
            'background-color: #D1FFFF;',
            'background-color: #FFD1FF;',
            'background-color: #D1D1B7;',
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
        // setup colors for hdims
        for (var i=0; i<hdim.length; i++) {
            hcol[i] = colors.pop()
            var idx = Math.max(0, vdim.length - 1);
        }

        // setup colors for vdims
        for (var i=0; i<vdim.length; i++) {
            vcol[i] = colors.pop();
            var idx = Math.max(0, hdim.length - 1);
        }

        var columns, thestore;
        [columns, thestore] = this.createStoreAndColumns(data, hdim, vdim, hcol, vcol);

        var dirty = false;
        var setDirty = function() { dirty = true; };
        var getDirty = function() { return dirty; };
        var me = this;
        var dataUpdate = function(grid, modFunc) {
            var store_data = grid.getStore().data.items;
            var newcolumns, newstore;
            var mod_data = [];
            modFunc(store_data, mod_data);
            [newcolumns, newstore] = me.createStoreAndColumns(mod_data, hdim, vdim, hcol, vcol);
            grid.reconfigure(newstore, newcolumns);
            Ext.each(grid.getColumns(), function(column) {
                column.autoSize();
            });
            setDirty();
        };
        var insertRow = function(inData, outData, rowIdx, up) {
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
        };
        var insertCol = function(inData, outData, colIdx, left) {
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
        var deleteRow = function(inData, outData, rowIdx) {
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
        };
        var deleteCol = function(inData, outData, colIdx) {
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
        };
        var lookup_grid = function () {
            return Ext.ComponentQuery.query('grid').find(function(v) {
                return v.name=='data_grid_edit_grid'
            });
        };
        var lookup_win = function () {
            return Ext.ComponentQuery.query('window').find(function(v) {
                return v.name=='data_grid_edit_window'
            });
        };
        var insertRowAboveAction = Ext.create('Ext.Action', {
            text: 'Insert Row Above',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    insertRow(data, mod_data, widget.position.row, true);
                });
            }
        });
        var insertRowBelowAction = Ext.create('Ext.Action', {
            text: 'Insert Row Below',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    insertRow(data, mod_data, widget.position.row, false);
                });
            }
        });
        var insertColLeftAction = Ext.create('Ext.Action', {
            text: 'Insert Column Left',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    insertCol(data, mod_data, widget.position.col, true);
                });
            }
        });
        var insertColRightAction = Ext.create('Ext.Action', {
            text: 'Insert Column Right',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    insertCol(data, mod_data, widget.position.col, false);
                });
            }
        });
        var deleteRowAction = Ext.create('Ext.Action', {
            text: 'Delete Row',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    deleteRow(data, mod_data, widget.position.row);
                });
            }
        });
        var deleteColAction = Ext.create('Ext.Action', {
            text: 'Delete Column',
            handler: function(widget , event) {
                var grid = lookup_grid();
                dataUpdate(grid, function(data, mod_data) {
                    deleteCol(data, mod_data, widget.position.col);
                });
            }
        });
        var itemContextMenu = Ext.create('Ext.menu.Menu' , {
            items: [insertRowAboveAction, insertRowBelowAction, insertColLeftAction,
                    insertColRightAction, deleteRowAction, deleteColAction]
        });

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

        var get_area = function(row, col) {
            var row_hdim = row < Math.max(1, hdim.length),
                row_vdim = col < Math.max(1, vdim.length);
            console.log("rowcol", row, col)
            console.log("rowcollen", Math.max(1, hdim.length), Math.max(1, vdim.length));
            var a;
            if (row_hdim && row_vdim)
                a = 'blank_area';
            else if (!row_hdim && !row_vdim)
                a = 'data_area';
            else if (row_hdim && !row_vdim)
                a = 'hdim_area';
            else a = 'vdim_area';
            console.log(a)
            return a;
        };
            
        var can_edit  = function(row, col) {
            var area = get_area(row, col);
            console.log(area);
            if (area == 'blank_area')
                return false;
            if (area == 'data_area')
                return permission != 'view';
            if (area == 'vdim_area' || area == 'hdim_area')
                return permission == 'edit_all';
        }

        // Plugins
        var cellEditor = Ext.create("Ext.grid.plugin.CellEditing", {

            clicksToEdit: 2,
            listeners: {
                beforeedit: function(editor, context, eOpts) {
                    if (!can_edit(context.rowIdx, context.colIdx - 1))
                        return false;
                },
                afteredit: function() {
                    setDirty();
                }
            }
        });

        var context_disable_fn = function(menu, label, x, y, fn) {
            var mi = menu.items.items.find(function (mi) {
                return mi.text == label;
            });
            if (fn(x, y)) 
                mi.disable();
            else
                mi.enable();
        };
        var row_menu_chk = function (ax, ay) {
            var area =  get_area(ax, ay - 1);
            if (vdim.length == 0)
                return true;
            return !(area == 'vdim_area' || area == 'data_area');
        };
        var col_menu_chk = function (ax, ay) {
            var area =  get_area(ax, ay - 1);
            if (hdim.length == 0)
                return true;
            return !(area == 'hdim_area' || area == 'data_area');
        };
        var disable_conds = [
            ['Insert Row Above',    row_menu_chk],
            ['Insert Row Below',    row_menu_chk],
            ['Delete Row',          row_menu_chk],
            ['Insert Column Left',  col_menu_chk],
            ['Insert Column Right', col_menu_chk],
            ['Delete Column',       col_menu_chk]
        ];
        Ext.define('DGEdit.grid.plugin.Clipboard',{
            override: 'Ext.grid.plugin.Clipboard',
            beforepaste: Ext.emptyFn,
            mixins: [
                'Ext.mixin.Observable'
            ],
            constructor: function(config) {
                var me = this;
                
                me.callParent([config]);
                me.mixins.observable.constructor.call(me);
            },
            privates : {
                onPaste: function (keyCode, event) {
                    var me = this,
                        sharedData = me.shared.data,
                        source = me.getSource(),
                        i, n, s,
                        rowIdx = event.position.rowIdx,
                        colIdx = event.position.colIdx - 1;
                    if (!can_edit(rowIdx, colIdx))  {
                        return;
                    }
                    if (me.fireEvent('beforepaste',keyCode,event,me.cmp) !== false) {                            
                        if (source) {
                            for (i = 0, n = source.length; i < n; ++i) {
                                s = source[i];
                                if (s === 'system') {
                                    // get the format used by the system clipboard. 
                                    s = me.getSystem();
                                    me.pasteClipboardData(s);
                                    break;
                                } else if (sharedData && (s in sharedData)) {
                                    me.doPaste(s, sharedData[s]);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        });
        Ext.define('DGEditController', {
            extend : 'Ext.app.ViewController',
            alias: 'controller.dataGridEdit',
            onBeforePaste:function(keyCode,event,grid){
                return false;
            }
        });
        Ext.tip.Tip.prototype.minWidth = void 0;
        Ext.tip.QuickTipManager.init();
        var grid = {
            xtype:       'grid',
            name:        'data_grid_edit_grid',
            border:      false,
            hideHeaders: false,
            autoEncode: true,
            controller: 'dataGridEdit',
            columns:     columns,
            scrollable: true,
            anchor: '100% 100%',
            forceFit: true,
            store:       thestore,
            plugins: [cellEditor,
                      {
                          ptype: 'clipboard',
                          system: 'raw',
              //            listeners: {
               //               beforepaste: 'onBeforePaste'
                //          }
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
                    var y = e.position.colIdx;
                    var x = e.position.rowIdx;
                    for (var i=0; i<ctn; ++i) {
                        items[i].position = {col: y, row: x};
                    }
                    for (const [label, fn] of disable_conds) {
                        context_disable_fn(itemContextMenu, label, x, y, fn);
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
                Ext.getBody().mask('Saving data...').setZIndex(99999).setStyle('cursor', 'wait');
                var grid = Ext.ComponentQuery.query('grid').find(function(v) {
                    return v.name=='data_grid_edit_grid'
                });
                var server = me.server;
                
                if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
                    var store = grid.getStore().data.items;
                    var ret = [];

                    // maybe remove label line at the top we added when hdim.length == 0
                    var row_start = hdim.length == 0 ? 1 : 0;
                    
                    for (var i = row_start; i < store.length; ++i) {
                        var row = {};

                        // maybe remove label col at the left we added when vdim.length == 0
                        var col_idx = 0;
                        var col0_skip = vdim.length == 0 ? true : false;

                        // or remove label fields we added in top left
                        var col_null = i < hdim.length ? vdim.length : 0;
                        
                        for (const [key, value] of Object.entries(store[i].data)) {
                            if (key != 'id' && !col0_skip) {
                                if (col_idx < col_null)
                                    row[key] = "";
                                else
                                    row[key] = value;
                            }
                            col0_skip = false;
                            col_idx++;
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
                            var win = lookup_win();
                            win.destroy();
                        }
                        Ext.getBody().unmask();
                    });
                }
                else
                {
                    Ext.getBody().unmask();
                    Ext.MessageBox.show({
                        title:'Nothing to Save',
                        msg: 'No changes made',
                        buttons: Ext.Msg.OK
                    });
                }
            },
            closeAction: 'destroy',
            listeners: {
                beforeclose: function (win) {
                    var grid = lookup_grid();
                    if(win.closeMe) {
                        win.closeMe = false;
                        grid.destroy();
                        return true;
                    }
                    if (getDirty() || grid.getStore().getModifiedRecords().length > 0) {
                        Ext.MessageBox.show({
                            title:'Discard Changes?',
                            msg: 'You are closing a window that has unsaved changes. Are you sure?',
                            buttons: Ext.Msg.YESNO,
                            icon: Ext.Msg.QUESTION,
                            /*
                            fn: function(btn){
                                if (btn == "no"){
                                    //NO
                                }
                                if (btn == "yes"){
                                    grid.destroy();
                                    win.doDestroy();
                                }
                            },
*/
                            callback: function(btn) {
                                if('yes' === btn) {
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
            fbar: [
                {
                    text: 'Save',
                    handler: function () {
                        this.up('window').submit();
                    }},
                {
                    text: 'Cancel',
                    handler: function () {
                        this.up('window').close();
                    }
                }]
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
