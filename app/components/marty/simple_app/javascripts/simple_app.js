{
  initComponent: function(){
    this.callParent();

    this.mainPanel = this.down('panel[itemId="main_panel"]');
    this.menuBar   = this.down('container[itemId="menu_bar"]');
    var statusBar = this.statusBar = this.down('container[itemId="status_bar"]');

    Ext.util.History.on('change', this.processHistory, this);

    // Setting the "busy" indicator for Ajax requests
    Ext.Ajax.on('beforerequest',    function(){ statusBar.showBusy(); });
    Ext.Ajax.on('requestcomplete',  function(){ statusBar.hideBusy(); });
    Ext.Ajax.on('requestexception', function(){ statusBar.hideBusy(); });

    // Initialize history
    Ext.util.History.init();
  },

  afterRender: function(){
    this.callParent();

    // If we are given a token, load the corresponding component, otherwise load the last loaded component
    var currentToken = Ext.util.History.getToken();
    if (currentToken != "") {
      this.processHistory(currentToken);
    } else {
      var lastLoaded = this.initialConfig.componentToLoad; // passed from the server
      if (lastLoaded) Ext.util.History.add(lastLoaded);
    }
  },

  // instantiateComponent: function(config){
  //   this.mainPanel.instantiateChild(config);
  // },

  appLoadComponent: function(name){
    this.netzkeLoadComponent(name, {container: this.mainPanel});
  },

  netzkeLoadComponentByAction: function(action){
    var componentName = action.component || action.name;
    if (componentName) this.netzkeLoadComponent(componentName, {container: this.mainPanel});
  },

  onToggleConfigMode: function(params){
    this.toggleConfigMode();
  }
}
