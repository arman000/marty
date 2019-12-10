{
  initComponent() {
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

  setRouting() {
    this.router = Ext.util.History;
    this.router.init();
    this.router.on('change', this.loadRoute, this);
  },

  loadRoute(token) {
    if (token) {
      this.netzkeLoadComponent(token, {
        container: this.mainPanel
      });
    } else {
      this.mainPanel.removeAll();
    }
  },

  afterRender() {
    this.callParent();
    var currentToken = this.router.getToken();
    if (typeof currentToken == "string" && currentToken.length > 0) {
      this.loadRoute(currentToken);
    }
  },

  appLoadComponent(name) {
    this.router.add(name);
  },

  netzkeLoadComponentByAction(action) {
    this.router.add(action.name.underscore());
  },

  onToggleConfigMode(params) {
    this.toggleConfigMode();
  },

  netzkeInitComponentCallback() {
  },

  // FIXME: move to netzke
  netzkeCallEndpoint(action) {
    const selected = this.getSelectionModel().getSelection().map((r) => r.id)
    const endpointName = action.endpointName || action.name;

    const camelCasedEndpointName = endpointName.replace(
      /_([a-z])/g,
      (g) => g[1].toUpperCase()
    );

    const requireConfirmation = action.requireConfirmation || action.confirmationMessage;

    const handlerFunction = this.server[camelCasedEndpointName];

    if (!requireConfirmation) {
      return handlerFunction(selected, () => { this.unmask()});
    };

    const confirmationTitle = action.confirmationTitle || action.name;
    const confirmationMessage = action.confirmationMessage || 'Are you sure?';
    const inProgressMessage = action.inProgressMessage || 'In progress...';

    return Ext.Msg.confirm(
      confirmationTitle,
      Ext.String.format(confirmationMessage),
      (btn, value, cfg) => {
        if (btn !== "yes") { return null; };
        this.mask(inProgressMessage);
        return handlerFunction(selected, () => { this.unmask()});
      }
    );
  },
}
