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

  netzkeReloadStore: function() {
    var store = this.getStore();

    // MONKEY: add netzkereload event on store
    store.fireEvent('netzkereload');

    // NETZKE'S HACK to work around buffered store's buggy reload()
    if (!store.lastRequestStart) {
      store.load();
    } else store.reload();
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
