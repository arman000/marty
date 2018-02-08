Ext.define('Marty.Grid.EventHandlers', {
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

Ext.define('Marty.Grid.Proxy',{
  override: 'Netzke.Grid.Proxy',
  read: function(operation, callback, scope) {
    this.reader.read(
      this.paramsFromOperation(operation),
      function(res){
	this.processResponse(true, operation, {}, res, callback, scope)
      }, this);
    return {};
    },
});
