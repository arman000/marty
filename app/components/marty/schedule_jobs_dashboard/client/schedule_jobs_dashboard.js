{
    netzkeOnDoJobRun: function(params) {
	Ext.Msg.confirm(
            'Run Job',
            Ext.String.format('Are you sure?'),
            (btn, value, cfg) => {
		if (btn == "yes") {
		    this.mask('Performing job...');
		    this.server.jobRun(() => { this.unmask()});
		}
            });
    }
}
