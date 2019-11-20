{
  initComponent: function () {
    this.callParent();

    this.mainPanel = this.down('panel[itemId="main_panel"]');
    this.menuBar = this.down('container[itemId="menu_bar"]');
    var statusBar = this.statusBar = this.down('container[itemId="status_bar"]');

    // Setting the "busy" indicator for Ajax requests
    Ext.Ajax.on('beforerequest', function () {
      statusBar.showBusy();
    });
    Ext.Ajax.on('requestcomplete', function () {
      statusBar.hideBusy();
    });
    Ext.Ajax.on('requestexception', function () {
      statusBar.hideBusy();
    });

    this.setRouting();
    this.netzkeInitComponentCallback();
  },

  setRouting: function () {
    this.router = Ext.util.History;
    this.router.init();
    this.router.on('change', this.loadRoute, this);
  },

  loadRoute: function (token) {
    if (token) {
      this.netzkeLoadComponent(token, {
        container: this.mainPanel
      });
    } else {
      this.mainPanel.removeAll();
    }
  },

  afterRender: function () {
    this.callParent();
    var currentToken = this.router.getToken();
    if (typeof currentToken == "string" && currentToken.length > 0) {
      this.loadRoute(currentToken);
    }
  },

  appLoadComponent: function (name) {
    this.router.add(name);
  },

  netzkeLoadComponentByAction: function (action) {
    this.router.add(action.name.underscore());
  },

  onToggleConfigMode: function (params) {
    this.toggleConfigMode();
  },

  netzkeInitComponentCallback: function() {
  },
}
