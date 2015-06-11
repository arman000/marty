{
  initComponent: function(){
    this.callParent();

    this.mainPanel = this.down('panel[itemId="main_panel"]');
    this.menuBar   = this.down('container[itemId="menu_bar"]');
    var statusBar = this.statusBar = this.down('container[itemId="status_bar"]');


    // Setting the "busy" indicator for Ajax requests
    Ext.Ajax.on('beforerequest',    function(){ statusBar.showBusy(); });
    Ext.Ajax.on('requestcomplete',  function(){ statusBar.hideBusy(); });
    Ext.Ajax.on('requestexception', function(){ statusBar.hideBusy(); });

    // Initialize history
    Ext.util.History.init();
    Ext.util.History.on('change', this.processHistory, this);
  },

  processHistory: function(token){
    if (token){
      this.mainPanel.removeAll();
      this.netzkeLoadComponent(token, {container: this.mainPanel});
    } else {
      this.mainPanel.removeAll();
    }
  },

  afterRender: function(){
    this.callParent();
    var currentToken = Ext.util.History.getToken();
    if (typeof currentToken == "string" && currentToken.length > 0) {
      this.processHistory(currentToken);
    }
  },

  appLoadComponent: function(name){
    this.netzkeLoadComponent(name, {container: this.mainPanel});
//    Ext.util.History.suspendEvent("change");
    Ext.util.History.add(name);
    // Can't re-enable history events right away because we don't
    // want a second load of the same component (causes ExtJS to
    // error). The back button won't function properly for the second
    // this is disabled.
//    setTimeout(function() {
//      Ext.util.History.resumeEvent("change");
//    }, 1000);
  },

  netzkeLoadComponentByAction: function(action){
    var componentName = action.component || action.name;
    if (componentName) this.appLoadComponent(componentName);
  },

  onToggleConfigMode: function(params){
    this.toggleConfigMode();
  }
}
