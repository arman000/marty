Ext.define('Netzke.Grid.EventHandlers', {
  override: 'Netzke.Grid.EventHandlers',
  netzkeHandleItemdblclick: function(view, record) {
    if (this.editsInline) return; // inline editing is handled elsewhere

    // MONKEY: add view in form capability
    var has_perm = (this.permissions || {});
    if (has_perm.read !== false && !has_perm.update) {
      this.doViewInForm(record);
    } else if (has_perm.update !== false) {
      this.doEditInForm(record);
    }
  },

    netzkeReloadStore: function(opts={}) {
    var store = this.getStore();

    // MONKEY: add beforenetzkereload and netzkerevent on store
    store.fireEvent('beforenetzkereload');
    var callback = opts.callback;
    opts.callback = function() {
      if (callback) { callback() }
      store.fireEvent('netzkereload');
    }

    // NETZKE'S HACK to work around buffered store's buggy reload()
    if (!store.lastRequestStart) {
      store.load(opts);
    } else store.reload(opts);
  },
});

Ext.define('Ext.toolbar.Paging', {
  override: 'Ext.toolbar.Paging',

  handleRefresh: Ext.emptyFn,

  doRefresh: function() {
    var me = this,
      current = me.store.currentPage;

    // MONKEY: add netzkerefresh to ExtJS paging toolbar refresh
    // as beforechange is too generic
    me.store.fireEvent('netzkerefresh', me);

    if (me.fireEvent('beforechange', me, current) !== false) {
      me.store.loadPage(current);

      me.handleRefresh();
    }
  }
});

Ext.define('Netzke.Grid.Columns', {
    override: 'Netzke.Grid.Columns',
      netzkeNormalizeAssociationRenderer: function(c) {
    var passedRenderer = c.renderer, // renderer we got from netzkeNormalizeRenderer
        assocValue;
    c.scope = this;
    c.renderer = function(value, a, r, ri, ci, store, view){
      var column = view.headerCt.items.getAt(ci),
          editor = column.getEditor && column.getEditor(),

	  /* MONKEY: use findRecordByValue instead of findRecord to remedy inline editing temporarily
	     changing N/A columns to the recently changed value.
	  */
          recordFromStore = editor && editor.isXType('combobox') && editor.findRecordByValue(value),
          renderedValue;

      if (recordFromStore) {
        renderedValue = recordFromStore.get('text');
      } else if ((assocValue = (r.get('association_values') || {})[c.name]) !== undefined) {
        renderedValue = (assocValue == undefined) ? c.emptyText : assocValue;
      } else {
        renderedValue = value;
      }

      return passedRenderer ? passedRenderer.call(this, renderedValue) : renderedValue;
    };
  },
});
