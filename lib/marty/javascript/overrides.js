Ext.define('Netzke.Grid.EventHandlers', {
  override: 'Netzke.Grid.EventHandlers',
  netzkeHandleItemdblclick: function(view, record){
    if (this.editsInline) return; // inline editing is handled elsewhere

    var has_perm = (this.permissions || {});
    if (has_perm.read !== false && !has_perm.update) {
      this.doViewInForm(record);
    }
    else if (has_perm.update !== false) {
      this.doEditInForm(record);
    }
  },
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
    
