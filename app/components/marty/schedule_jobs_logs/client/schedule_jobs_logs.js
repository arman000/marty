{
    netzkeOnDestroyAll: function(params) {
    Ext.Msg.confirm(
      'Delete all',
      Ext.String.format('Are you sure?'),
      (btn, value, cfg) => {
        if (btn == "yes") {
          this.mask('Deleting...');
          this.server.destroyAll(() => { this.unmask()});
        }
      });
    }
}
